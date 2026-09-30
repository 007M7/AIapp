import Foundation

/// 配网流程的界面状态机(对应 PRD `19` 页面树 device/bind → device/provision)。
/// 步骤 UI 文案:1 搜索设备 → 2 连接手办(蓝牙) → 3 握手(Security 1) → 4 写入 WiFi → 5 查询联网结果。
@MainActor
final class Provisioner: ObservableObject {
    enum Stage: Equatable {
        case idle
        case scanning
        case connecting       // 连接 + proto-ver + 握手
        case readyForWifi
        case provisioning     // 发送 WiFi / 等待联网
        case success(ip: String)
        case failed(String)
    }

    @Published private(set) var stage: Stage = .idle
    @Published private(set) var devices: [ProtocommBLE.Found] = []
    @Published private(set) var stepLine = ""
    @Published var ssid = ""
    @Published var password = ""

    private let ble = ProtocommBLE()
    private var session: ProvisionSession?
    private var deviceId: UUID?

    var passwordHidden: Bool { true }

    func startScan() {
        guard stage == .idle || stage == .scanning || isTerminal else {
            close()   // 从失败/成功态重新开始
        }
        devices = []
        stage = .scanning
        do {
            try ble.startScan { [weak self] found in
                Task { @MainActor in self?.upsert(found) }
            }
        } catch {
            stage = .failed(error.localizedDescription)
        }
    }

    private var isTerminal: Bool {
        if case .success = stage { return true }
        if case .failed = stage { return true }
        return false
    }

    private func upsert(_ f: ProtocommBLE.Found) {
        if let i = devices.firstIndex(where: { $0.id == f.id }) {
            devices[i] = f
        } else {
            devices.append(f)
            devices.sort { $0.rssi > $1.rssi }
        }
    }

    func stopScan() { ble.stopScan() }

    func connect(_ found: ProtocommBLE.Found) async {
        stopScan()
        deviceId = found.id
        stage = .connecting
        stepLine = "连接手办(蓝牙)…"
        do {
            try await ble.connect(found.id) { [weak self] in
                Task { @MainActor in
                    self?.session = nil
                    if self?.stage == .readyForWifi || self?.stage == .connecting {
                        self?.stage = .failed("蓝牙连接已断开,请重新开始配网")
                    }
                }
            }
            stepLine = "确认固件与安全方案…"
            let session = ProvisionSession { [ble] name, data in
                guard let ep = ProtocommBLE.endpointByName[name] else {
                    throw ProvError.ble("未知的配网端点:\(name)")
                }
                return try await ble.xfer(ep, data)
            }
            self.session = session
            try await session.protoVer()
            stepLine = "建立加密握手(Security 1)…"
            try await session.handshake()
            stage = .readyForWifi
            stepLine = ""
        } catch {
            ble.close()
            session = nil
            stage = .failed(error.localizedDescription)
        }
    }

    func sendWifi() async {
        guard let session else { return }
        stage = .provisioning
        do {
            let outcome = try await session.provision(
                ssid: ssid.trimmingCharacters(in: .whitespacesAndNewlines),
                pass: password,
                onStep: { [weak self] line in
                    Task { @MainActor in self?.stepLine = line }
                })
            switch outcome {
            case .connected(let ip):
                stage = .success(ip: ip)
                stepLine = ""
            case .failed(let reason):
                stage = .failed(reason == "auth" ? "WiFi 密码好像不对,检查后重试" : "找不到这个 WiFi,确认名称后重试")
            case .timeout:
                stage = .failed("手办还在连 WiFi。可以稍后在设备设置里重试,或从头再配一次")
            case .connecting:
                stage = .failed("连接超时,请重试")
            }
        } catch {
            stage = .failed(error.localizedDescription)
        }
    }

    /// 从失败态重开(重开会话作废,必须重新握手)
    func reset() {
        close()
        startScan()
    }

    /// 离开页面时调
    func close() {
        ble.close()
        session = nil
        stage = .idle
        stepLine = ""
    }
}
