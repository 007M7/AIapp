import Foundation

struct LabTelemetry: Decodable {
    let state: String
    let usbPresent: Bool
    let batteryMv: Int
    let batteryValidation: String
    let batteryPercent: Double?
    let charging: Bool?
    let rssi: Int
}

struct LabDeviceStatus: Decodable {
    let deviceId: String
    let deviceOnline: Bool
    let firmware: String
    let supportsIdentify: Bool
    let canIdentify: Bool
    let telemetryFresh: Bool
    let telemetryAt: Double?
    let telemetry: LabTelemetry?
    let pendingOperationId: String?
    let busy: Bool?
    let serviceReady: Bool?
    let supportsMobileVoice: Bool?
    let canMobileVoice: Bool?
    let powerMode: String?

    var stateLabel: String {
        if !deviceOnline { return "未连接" }
        if serviceReady == false { return "暂时无法互动" }
        guard telemetryFresh, let telemetry else { return busy == true ? "互动进行中" : "等待状态更新" }
        switch telemetry.state {
        case "REC": return "正在听"
        case "WAIT": return "处理中"
        case "PLAY": return "正在回应"
        case "IDLE": return busy == true ? "互动进行中" : "可互动"
        default: return "暂时无法互动"
        }
    }
}

struct LabOperation: Decodable {
    let id: String
    let status: String
    let code: String
    let created: Double
    let updated: Double
    let kind: String?

    var waiting: Bool { ["accepted", "sent", "running"].contains(status) }
    var label: String {
        switch status {
        case "accepted": return "服务器已受理"
        case "sent": return "已发送，等待设备回执"
        case "running": return "设备正在执行"
        case "completed": return kind == "voice" ? "回答已播放完毕" : "设备已执行，请核对短鸣"
        case "rejected": return "设备未执行"
        case "failed": return "设备执行失败"
        default: return "结果未确认，不会自动重发"
        }
    }
}

struct LabClientError: LocalizedError {
    let status: Int?
    let message: String
    var errorDescription: String? { message }
}

/// Execution-only LAN client; separate from platform login and ServerConfig.
final class DeviceLabClient {
    private let base: URL
    private let token: String
    private let session: URLSession

    static func validatedBase(_ text: String) throws -> URL {
        guard let url = URL(string: text.trimmingCharacters(in: .whitespacesAndNewlines)),
              let host = url.host?.lowercased(), let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme), url.user == nil, url.password == nil,
              url.query == nil, url.fragment == nil, ["", "/"].contains(url.path),
              url.port == nil || (1...65535).contains(url.port!) else {
            throw LabClientError(status: nil, message: "请填写正确的服务器地址")
        }
        if scheme == "http" {
            let parts = host.split(separator: ".", omittingEmptySubsequences: false)
            let bytes = parts.compactMap { Int($0) }
            let ipv4 = parts.count == 4 && bytes.count == 4 && bytes.allSatisfy { (0...255).contains($0) }
                && parts.allSatisfy { String(Int($0) ?? -1) == String($0) }
            let local = host == "localhost" || (ipv4 && (bytes[0] == 127 || bytes[0] == 10 ||
                (bytes[0] == 172 && (16...31).contains(bytes[1])) || (bytes[0] == 192 && bytes[1] == 168)))
            guard local else { throw LabClientError(status: nil, message: "HTTP 仅用于本机或私网联调") }
        }
        return url
    }

    init(address: String, token: String, session: URLSession? = nil) throws {
        base = try Self.validatedBase(address)
        let credential = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard credential.count >= 32, credential.rangeOfCharacter(from: .whitespacesAndNewlines) == nil else {
            throw LabClientError(status: nil, message: "请填写独立的联调凭据")
        }
        self.token = credential
        if let session { self.session = session }
        else {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.httpShouldSetCookies = false
            configuration.urlCredentialStorage = nil
            configuration.timeoutIntervalForRequest = 6
            self.session = URLSession(configuration: configuration)
        }
    }

    private struct Envelope<T: Decodable>: Decodable { let data: T }
    private struct ErrorEnvelope: Decodable {
        struct Detail: Decodable { let message: String }
        let error: Detail
    }

    private func request<T: Decodable>(_ path: String, key: UUID? = nil, audio: Data? = nil) async throws -> T {
        var request = URLRequest(url: base.appendingPathComponent(path))
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 6
        if let key {
            request.httpMethod = "POST"
            request.httpBody = audio ?? Data("{}".utf8)
            request.setValue(audio == nil ? "application/json" : "application/octet-stream", forHTTPHeaderField: "Content-Type")
            request.setValue(key.uuidString, forHTTPHeaderField: "Idempotency-Key")
        }
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw LabClientError(status: nil, message: "服务器响应格式不匹配")
        }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        guard (200..<300).contains(http.statusCode) else {
            let message = (try? decoder.decode(ErrorEnvelope.self, from: data))?.error.message ?? "服务器暂时不可用"
            throw LabClientError(status: http.statusCode, message: message)
        }
        return try decoder.decode(Envelope<T>.self, from: data).data
    }

    func status() async throws -> LabDeviceStatus { try await request("lab/v1/status") }
    func identify(key: UUID) async throws -> LabOperation { try await request("lab/v1/identify", key: key) }
    func voice(_ pcm: Data, key: UUID) async throws -> LabOperation {
        guard (16000...960000).contains(pcm.count), pcm.count % 2 == 0 else {
            throw LabClientError(status: 400, message: "请录制0.5至30秒语音")
        }
        return try await request("lab/v1/voice", key: key, audio: pcm)
    }
    func operation(_ id: String) async throws -> LabOperation {
        guard id.count == 32, id.allSatisfy({ "0123456789abcdef".contains($0) }) else {
            throw LabClientError(status: nil, message: "操作编号无效")
        }
        return try await request("lab/v1/operations/\(id)")
    }
}
