import Foundation
import Combine
import Security

struct DeviceConnectionCode: Decodable {
    let type: String
    let server: String
    let credential: String

    static func parse(_ text: String) throws -> Self {
        guard text.utf8.count <= 4096, let data = text.data(using: .utf8),
              let value = try? JSONDecoder().decode(Self.self, from: data), value.type == "aifigure.device.v1" else {
            throw LabClientError(status: nil, message: "这不是手办连接码")
        }
        _ = try DeviceLabClient(address: value.server, token: value.credential)
        return value
    }
}

enum DeviceCredential {
    private static let service = "com.aiapp.figure.device-pilot"
    static func read() -> String? {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service, kSecAttrAccount as String: "connection",
            kSecReturnData as String: true, kSecMatchLimit as String: kSecMatchLimitOne]
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
    static func write(_ value: String?) throws {
        let key: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service, kSecAttrAccount as String: "connection"]
        if let value {
            let data = Data(value.utf8)
            let update = SecItemUpdate(key as CFDictionary, [kSecValueData as String: data] as CFDictionary)
            if update == errSecItemNotFound {
                var item = key
                item[kSecValueData as String] = data
                item[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
                guard SecItemAdd(item as CFDictionary, nil) == errSecSuccess else {
                    throw LabClientError(status: nil, message: "无法保存连接凭据")
                }
            } else if update != errSecSuccess {
                throw LabClientError(status: nil, message: "无法保存连接凭据")
            }
        } else { SecItemDelete(key as CFDictionary) }
    }
}

@MainActor
final class DevicePilotStore: ObservableObject {
    @Published var address = UserDefaults.standard.string(forKey: "device-pilot.address") ?? "http://192.168.137.1:8795"
    @Published var credential = ""
    @Published private(set) var status: LabDeviceStatus?
    @Published private(set) var operation: LabOperation?
    @Published private(set) var connecting = false
    @Published private(set) var sending = false
    @Published private(set) var message = ""
    @Published private(set) var connected = false
    private var client: DeviceLabClient?
    private var generation = UUID()
    private var polling: Task<Void, Never>?
    private var submitting: Task<Void, Never>?
    private var uncertain = false
    private var requestPending = false

    var stateTitle: String {
        if connecting { return "正在连接" }
        guard connected else { return "连接手办" }
        if !message.isEmpty { return "等待状态更新" }
        guard let status else { return "等待状态更新" }
        return status.stateLabel
    }
    var canIdentify: Bool {
        connected && message.isEmpty && status?.canIdentify == true && !sending && !requestPending && !uncertain
    }
    var powerTitle: String {
        guard status?.deviceOnline == true, status?.telemetryFresh == true,
              let telemetry = status?.telemetry else { return "供电状态未知" }
        return telemetry.usbPresent ? "已接电源" : "未检测到外接电源"
    }
    var lastContact: String {
        guard let timestamp = status?.telemetryAt else { return "暂无记录" }
        return Date(timeIntervalSince1970: timestamp).formatted(date: .omitted, time: .standard)
    }

    func resume() {
        if client != nil { startPolling(); return }
        if let saved = DeviceCredential.read() {
            credential = saved
            submitting = Task { await connect() }
        }
    }
    func pause() {
        polling?.cancel(); polling = nil
        submitting?.cancel(); submitting = nil
        if sending { uncertain = true; sending = false }
        requestPending = false
        generation = UUID()
        connecting = false
    }
    func disconnect() {
        pause(); client = nil; connected = false; status = nil; operation = nil
        credential = ""; message = ""; connecting = false; uncertain = false
        try? DeviceCredential.write(nil)
    }
    func importCode(_ code: DeviceConnectionCode) async {
        disconnect(); address = code.server; credential = code.credential
        await connect()
    }
    func connect() async {
        guard !connecting else { return }
        polling?.cancel(); polling = nil; generation = UUID()
        let stamp = generation
        client = nil; status = nil; operation = nil; connected = false
        connecting = true; message = ""; uncertain = false
        defer { if generation == stamp { connecting = false } }
        do {
            let proposed = try DeviceLabClient(address: address, token: credential)
            let snapshot = try await proposed.status()
            guard generation == stamp, !Task.isCancelled else { return }
            try DeviceCredential.write(credential)
            UserDefaults.standard.set(address, forKey: "device-pilot.address")
            credential = ""; client = proposed; status = snapshot; connected = true
            startPolling()
        } catch {
            if generation == stamp, !Task.isCancelled { message = friendly(error) }
        }
    }
    func refresh() async {
        guard let client else { return }
        let stamp = generation
        do {
            let snapshot = try await client.status()
            guard generation == stamp, !Task.isCancelled else { return }
            status = snapshot; message = ""
            if !requestPending, let id = operation?.id ?? snapshot.pendingOperationId {
                let result = try await client.operation(id)
                guard generation == stamp, !Task.isCancelled else { return }
                guard !requestPending, operation == nil || operation?.id == id else { return }
                operation = result
                sending = result.waiting
                if !result.waiting { uncertain = result.status == "unknown" }
            }
        } catch {
            guard generation == stamp, !Task.isCancelled else { return }
            if let failure = error as? LabClientError, [401,403].contains(failure.status ?? 0) {
                disconnect(); message = "连接凭据已失效，请重新扫码"
            } else { message = friendly(error) }
        }
    }
    func identify() {
        guard canIdentify, let client else { return }
        sending = true; requestPending = true; operation = nil; message = ""
        let stamp = generation, key = UUID()
        submitting = Task {
            do {
                let result = try await client.identify(key: key)
                guard generation == stamp, !Task.isCancelled else { return }
                requestPending = false; operation = result; sending = result.waiting
                await refresh()
            } catch {
                guard generation == stamp, !Task.isCancelled else { return }
                requestPending = false; sending = false
                uncertain = (error as? LabClientError)?.status == nil
                message = uncertain ? "结果未确认，请查看手办；不会自动重发" : friendly(error)
            }
        }
    }
    private func startPolling() {
        polling?.cancel()
        polling = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refresh()
                do { try await Task.sleep(nanoseconds: 2_000_000_000) } catch { break }
            }
        }
    }
    private func friendly(_ error: Error) -> String {
        if let failure = error as? LabClientError { return failure.message }
        if let failure = error as? URLError, failure.code == .notConnectedToInternet {
            return "请将iPhone连接到手办所在的Wi-Fi"
        }
        return "暂时连不上设备服务，请检查Wi-Fi与电脑服务"
    }
}
