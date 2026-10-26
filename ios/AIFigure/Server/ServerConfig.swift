import Foundation
import Combine

/// 服务器接入配置。App 走**标准 TLS** 的 api 域名(nginx SNI 分流后的那一侧);
/// 设备侧 TLS-PSK 域名 App 进不去,也不需要进(`14` §5.5 部署形态)。
/// MVP:baseURL + token 手动填(开发期);App 登录方式(微信 SDK / 手机号)待定,
/// 见 09 登记表 Q-88。
final class ServerConfig: ObservableObject {
    static let shared = ServerConfig()

    private let defaults: UserDefaults

    private static let baseURLKey = "server.baseURL"
    private static let tokenKey = "server.token"

    @Published private(set) var revision = UUID()

    @Published var baseURL: String {
        didSet { defaults.set(baseURL, forKey: Self.baseURLKey); revision = UUID() }
    }
    @Published var token: String {
        didSet { defaults.set(token, forKey: Self.tokenKey); revision = UUID() }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        baseURL = defaults.string(forKey: Self.baseURLKey) ?? ""
        token = defaults.string(forKey: Self.tokenKey) ?? ""
    }

    var isConfigured: Bool {
        guard let url = apiBase, let host = url.host else { return false }
        return !host.isEmpty
    }

    var apiBase: URL? {
        let s = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return nil }
        return URL(string: s)
    }
}
