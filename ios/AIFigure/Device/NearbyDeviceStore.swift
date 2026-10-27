import Foundation
import Combine
import Security

private enum BLEOwnerCredential {
    static func loadOrCreate(_ device: UUID) throws -> String {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.aiapp.figure.ble-owner", kSecAttrAccount as String: device.uuidString]
        var read = query; read[kSecReturnData as String] = true; read[kSecMatchLimit as String] = kSecMatchLimitOne
        var value: CFTypeRef?
        let result = SecItemCopyMatching(read as CFDictionary, &value)
        if result == errSecSuccess, let data = value as? Data, let key = String(data: data, encoding: .utf8) { return key }
        guard result == errSecItemNotFound else { throw ProvError.session("请解锁手机后重新连接") }
        var bytes = [UInt8](repeating: 0, count: 32)
        guard SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes) == errSecSuccess else { throw ProvError.session("无法创建设备授权") }
        let key = bytes.map { String(format: "%02x", $0) }.joined()
        var item = query; item[kSecValueData as String] = Data(key.utf8)
        item[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        guard SecItemAdd(item as CFDictionary, nil) == errSecSuccess else { throw ProvError.session("无法保存设备授权") }
        return key
    }
}

@MainActor
final class NearbyDeviceStore: ObservableObject {
    @Published private(set) var devices: [ProtocommBLE.Found] = []
    @Published private(set) var connected = false
    @Published private(set) var scanning = false
    @Published private(set) var connecting = false
    @Published private(set) var working = false
    @Published private(set) var status: BLEDeviceStatus?
    @Published private(set) var message = ""
    @Published private(set) var name = "小鲸"
    @Published private(set) var gateway: DeviceConnectionCode?
    private let ble = ProtocommBLE(management: true)
    private var session: ProvisionSession?
    private var key = ""
    private var generation = UUID()
    private var polling: Task<Void, Never>?
    private var action: Task<Void, Never>?
    private var lastGateway = ""
    private var deviceID: UUID?
    func resume() {
        guard !connected, !connecting, !scanning, !working,
              let saved = UserDefaults.standard.string(forKey: "ble-device.id"), let id = UUID(uuidString: saved) else { return }
        connect(ProtocommBLE.Found(id: id, name: "小鲸", rssi: 0))
    }

    func scan() {
        guard !connecting, !working else { return }
        close(); devices = []; scanning = true; message = "正在寻找附近的手办…"
        let stamp = generation
        action = Task {
            do {
                try await ble.waitReady()
                guard stamp == generation, !Task.isCancelled else { return }
                try ble.startScan { [weak self] found in
                    Task { @MainActor in
                        guard let self, self.generation == stamp else { return }
                        if let i = self.devices.firstIndex(where: { $0.id == found.id }) { self.devices[i] = found }
                        else { self.devices.append(found) }
                        self.devices.sort { $0.rssi > $1.rssi }
                        self.message = "选择你的手办"
                    }
                }
            } catch { if stamp == generation { scanning = false; message = error.localizedDescription } }
        }
    }
    func connect(_ found: ProtocommBLE.Found) {
        guard !connecting, !working else { return }
        ble.stopScan(); scanning = false; connecting = true; message = "正在连接…"
        let stamp = generation
        action = Task {
            do {
                key = try BLEOwnerCredential.loadOrCreate(found.id)
                deviceID = found.id
                try await ble.connect(found.id) { [weak self] in self?.lostConnection() }
                let secure = ProvisionSession { [ble] endpoint, data in
                    guard let ep = ProtocommBLE.endpointByName[endpoint] else { throw ProvError.ble("未知端点") }
                    return try await ble.xfer(ep, data)
                }
                session = secure
                try await secure.protoVer(); try await secure.handshake()
                var authorized = false
                for _ in 0..<60 {
                    guard stamp == generation, !Task.isCancelled else { return }
                    let value = try await exchange("auth")
                    if value["result"] as? String == "completed" { authorized = true; break }
                    if value["result"] as? String != "confirm" { throw ProvError.session(BLEControlProtocol.failure(value["code"] as? String ?? "")) }
                    message = "请轻按一次主板说话键，确认连接"
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                }
                guard authorized else { throw ProvError.session("确认超时，请重新连接") }
                guard stamp == generation, !Task.isCancelled else { return }
                connected = true; connecting = false; name = found.name; message = "蓝牙已连接"
                UserDefaults.standard.set(found.id.uuidString, forKey: "ble-device.id")
                await refresh()
                startPolling()
            } catch { if stamp == generation { close(); message = error.localizedDescription } }
        }
    }
    private func exchange(_ op: String, id: String? = nil, fields: [String: Any] = [:]) async throws -> [String: Any] {
        guard let session else { throw ProvError.ble("请先连接蓝牙") }
        let data = try BLEControlProtocol.request(op: op, key: key, id: id, fields: fields)
        return try BLEControlProtocol.reply(try await session.control(data))
    }
    func refresh() async {
        guard connected, !working else { return }
        working = true; defer { working = false }
        do { try await readStatus() } catch { message = error.localizedDescription }
    }
    private func readStatus() async throws {
        let value = try await exchange("status")
        guard value["result"] as? String == "completed" else { throw ProvError.session(BLEControlProtocol.failure(value["code"] as? String ?? "")) }
        let current = try JSONDecoder().decode(BLEDeviceStatus.self, from: JSONSerialization.data(withJSONObject: value))
        status = current
        message = ""
        if current.wifi, current.ready, lastGateway != current.host {
            let code = try await exchange("gateway")
            let data = try JSONSerialization.data(withJSONObject: ["type": "aifigure.device.v1", "server": code["server"] as? String ?? "", "credential": code["credential"] as? String ?? ""])
            gateway = try DeviceConnectionCode.parse(String(decoding: data, as: UTF8.self))
            lastGateway = current.host
        }
    }
    func command(_ op: String, fields: [String: Any] = [:]) {
        guard connected, !working else { return }
        working = true; message = "正在执行…"
        let stamp = generation, id = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
        action = Task {
            defer { if stamp == generation { working = false } }
            do {
                let accepted = try await exchange(op, id: id, fields: fields)
                guard accepted["result"] as? String == "accepted" || accepted["result"] as? String == "running" else {
                    throw ProvError.session(BLEControlProtocol.failure(accepted["code"] as? String ?? ""))
                }
                for _ in 0..<90 {
                    try await Task.sleep(nanoseconds: 500_000_000)
                    guard stamp == generation, !Task.isCancelled else { return }
                    let result = try await exchange("result", id: id)
                    let state = result["result"] as? String
                    if state == "completed" { message = op == "wifi" ? "网络已更新" : "已完成"; try await readStatus(); return }
                    if state == "failed" || state == "rejected" { throw ProvError.session(BLEControlProtocol.failure(result["code"] as? String ?? "")) }
                    if state == "unknown" { throw ProvError.session("操作结果未确认，请核对状态；不会自动重发") }
                }
                message = "操作结果未确认，请核对状态；不会自动重发"
            } catch { if stamp == generation { message = error.localizedDescription } }
        }
    }
    private func startPolling() {
        polling?.cancel()
        polling = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refresh()
                do { try await Task.sleep(nanoseconds: 1_500_000_000) } catch { return }
            }
        }
    }
    private func lostConnection() { close(); message = "蓝牙已断开，请靠近手办后重新连接" }
    func close() {
        generation = UUID(); polling?.cancel(); polling = nil; action?.cancel(); action = nil
        ble.close(); session = nil; key = ""; connected = false; connecting = false; scanning = false; working = false
        status = nil; gateway = nil; lastGateway = ""; deviceID = nil
    }
}
