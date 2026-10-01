import Foundation

struct APIError: LocalizedError {
    let status: Int
    let message: String
    var errorDescription: String? { message.isEmpty ? "服务器返回 \(status)" : message }
}

/// `/api/v1` 客户端。端点清单唯一权威:AI_figure `docs/product/14 §5.4`(注释里的 # 号 = 该表行号)。
/// 实现了 UI 本期用到的端点;响应字段口径以服务端实际落地为准,缺口统一登记在 09 的 Q-87。
final class APIClient {
    private let config: ServerConfig
    private let session: URLSession
    private let decoder: JSONDecoder

    init(config: ServerConfig = .shared, session: URLSession = .shared) {
        self.config = config
        self.session = session
        decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
    }

    // MARK: - 基础请求

    private func request<T: Decodable>(_ method: String, _ path: String,
                                       query: [String: String] = [:],
                                       body: [String: Any]? = nil) async throws -> T {
        guard config.isConfigured else { throw APIError(status: 0, message: "还没有配置服务器地址;到「我的 → 设置」里填入 api 域名") }
        var comps = URLComponents(url: config.apiBase!.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        if !query.isEmpty {
            comps.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        var req = URLRequest(url: comps.url!)
        req.httpMethod = method
        if !config.token.isEmpty { req.setValue("Bearer \(config.token)", forHTTPHeaderField: "Authorization") }
        if let body {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw APIError(status: 0, message: "响应格式不对") }
        guard (200 ..< 300).contains(http.statusCode) else {
            let msg = (try? decoder.decode(APIEnvelope.self, from: data))?.message ?? ""
            throw APIError(status: http.statusCode, message: msg)
        }
        // 204/空体(DELETE 等)按 Empty 处理,别去解 JSON(实际踩过)
        if data.isEmpty, let empty = Empty() as? T { return empty }
        return try decoder.decode(T.self, from: data)
    }

    private struct APIEnvelope: Decodable { let message: String? }

    // MARK: - 账号与设备(绑定地基)

    func me() async throws -> MeInfo { try await request("GET", "api/v1/me") }                                   // #2
    func claimDevice(sn: String) async throws -> DeviceItem {                                                    // #3
        try await request("POST", "api/v1/devices/claim", body: ["sn": sn])
    }
    func devices() async throws -> [DeviceItem] { try await request("GET", "api/v1/devices") }                   // #4
    func device(_ id: String) async throws -> DeviceItem { try await request("GET", "api/v1/devices/\(id)") }    // #5
    func unbindDevice(_ id: String) async throws -> Empty {                                                      // #7
        try await request("DELETE", "api/v1/devices/\(id)/binding")
    }

    // MARK: - 角色(收藏册主视图)

    func characters() async throws -> [FigureCharacter] { try await request("GET", "api/v1/characters") }        // #25
    func character(_ id: String) async throws -> FigureCharacter {                                               // #13
        try await request("GET", "api/v1/characters/\(id)")
    }
    func installPack(_ packId: String) async throws -> FigureCharacter {                                         // #22
        try await request("POST", "api/v1/packs/\(packId)/install")
    }

    // MARK: - 记忆(查看/编辑/删除/封存;用户主动删 = 硬删)

    func memories(characterId: String) async throws -> [MemoryItem] {                                            // #16
        try await request("GET", "api/v1/memories", query: ["character_id": characterId])
    }
    func updateMemory(_ id: String, factText: String, status: String? = nil) async throws -> MemoryItem {       // #17 PUT
        var body: [String: Any] = ["fact_text": factText]
        if let status { body["status"] = status }
        return try await request("PUT", "api/v1/memories/\(id)", body: body)
    }
    func deleteMemory(_ id: String) async throws -> Empty {                                                      // #17 DELETE
        try await request("DELETE", "api/v1/memories/\(id)")
    }
    func clearMemories(characterId: String) async throws -> Empty {                                              // #17 clear
        try await request("POST", "api/v1/memories/clear", query: ["character_id": characterId])
    }

    // MARK: - 对话记录与文字回合

    func turns(characterId: String) async throws -> [TurnItem] {                                                 // #18
        try await request("GET", "api/v1/characters/\(characterId)/turns")
    }
    /// App 端文字发一轮、收文本+音频结果。V1 不承诺设备同步出声(#24 复核 high 裁决)。
    /// 响应字段(audio_url / audio_base64)为约定草案,以服务端落地为准(Q-87)。
    func textTurn(characterId: String, text: String) async throws -> TextTurnResult {                            // #24
        try await request("POST", "api/v1/characters/\(characterId)/text-turn", body: ["text": text])
    }

    // MARK: - 商店与社区

    func packs() async throws -> [PackItem] { try await request("GET", "api/v1/packs") }                         // #11
    func audition(_ packId: String) async throws -> AuditionResult {                                             // #15
        try await request("POST", "api/v1/packs/\(packId)/audition")
    }
    func posts() async throws -> [CommunityPost] { try await request("GET", "api/v1/community/posts") }          // #20
    func react(postId: String, kind: String) async throws -> Empty {                                             // #23
        try await request("POST", "api/v1/community/posts/\(postId)/react", body: ["kind": kind])
    }
}

/// 端点返回空体时用
struct Empty: Codable {}
