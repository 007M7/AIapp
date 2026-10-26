import Foundation
import Combine

enum CollectionPhase: Equatable {
    case idle, loading, unconfigured, empty, loaded
    case failed(String)
}

/// 页面列表状态；没有持久缓存，不拥有服务端业务事实。
final class RemoteCollection<Item>: ObservableObject {
    @Published private(set) var items: [Item] = []
    @Published private(set) var phase: CollectionPhase = .idle
    private var generation = 0

    @MainActor
    func load(config: ServerConfig = .shared,
              fetch: () async throws -> [Item]) async {
        generation += 1
        let requestGeneration = generation
        let revision = config.revision
        items = []
        guard config.isConfigured else {
            phase = .unconfigured
            return
        }
        phase = .loading
        do {
            let result = try await fetch()
            guard generation == requestGeneration, revision == config.revision else { return }
            guard !Task.isCancelled else { phase = .idle; return }
            items = result
            phase = result.isEmpty ? .empty : .loaded
        } catch {
            guard generation == requestGeneration, revision == config.revision else { return }
            if Task.isCancelled || (error as? URLError)?.code == .cancelled {
                phase = .idle
            } else {
                phase = .failed(Self.message(for: error))
            }
        }
    }

    private static func message(for error: Error) -> String {
        if let error = error as? APIError {
            switch error.status {
            case 401: return "登录状态已失效，请检查接入设置后重试。"
            case 403: return "当前账号无法查看这些内容。"
            case 429: return "请求较多，请稍后再试。"
            case 500...599: return "服务暂时没有回应，请稍后重试。"
            default: return "暂时无法读取内容，请检查接入设置或重试。"
            }
        }
        if let error = error as? URLError, error.code == .notConnectedToInternet {
            return "网络没有连上，恢复网络后再试。"
        }
        return "暂时无法读取内容，请检查网络后重试。"
    }
}
