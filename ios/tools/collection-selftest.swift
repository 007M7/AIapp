import Foundation

@main
struct CollectionSelftest {
    @MainActor
    static func main() async throws {
        let suite = "aiapp.collection-test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let config = ServerConfig(defaults: defaults)
        let list = RemoteCollection<Int>()

        await list.load(config: config) { assertionFailure("未配置时不能请求"); return [1] }
        assert(list.phase == .unconfigured)
        config.baseURL = "https://api.example.cn"
        await list.load(config: config) { [] }
        assert(list.phase == .empty)
        await list.load(config: config) { throw APIError(status: 401, message: "internal-secret") }
        guard case .failed(let message) = list.phase else { fatalError("失败不能变成空列表") }
        assert(!message.contains("internal-secret"))

        // 旧请求更晚返回时，不允许覆盖更新一次读取的结果。
        let old = Task {
            await list.load(config: config) {
                try await Task.sleep(nanoseconds: 80_000_000)
                return [1]
            }
        }
        try await Task.sleep(nanoseconds: 10_000_000)
        await list.load(config: config) { [2] }
        await old.value
        assert(list.items == [2] && list.phase == .loaded)

        // 接入身份变化后，即使旧请求成功，也不能回填私人数据。
        let stale = Task {
            await list.load(config: config) {
                try await Task.sleep(nanoseconds: 80_000_000)
                return [9]
            }
        }
        try await Task.sleep(nanoseconds: 10_000_000)
        config.token = "different-test-identity"
        await list.load(config: config) { [3] }
        await stale.value
        assert(list.items == [3])

        let cancelled = Task {
            await list.load(config: config) {
                try await Task.sleep(nanoseconds: 100_000_000)
                return [4]
            }
        }
        try await Task.sleep(nanoseconds: 10_000_000)
        cancelled.cancel()
        await cancelled.value
        assert(list.items.isEmpty && list.phase == .idle)
        print("列表状态：未配置、空态、失败、错误脱敏、并发过期、身份变化与取消检查通过")
    }
}
