import Foundation
import Combine

@MainActor final class DeviceChatStore: ObservableObject {
    @Published private(set) var cache=ChatHistoryCache()
    @Published private(set) var note=""
    @Published private(set) var loading=false
    private var scope=""
    private var polling: Task<Void,Never>?
    private var generation=UUID()
    func start(_ device: DevicePilotStore) {
        stop()
        let expected=device.chatScope
        scope=device.status?.deviceId == nil ? UserDefaults.standard.string(forKey:"chat.last-scope") ?? expected : expected
        if !scope.hasPrefix(device.address+"|") { scope=expected;cache=ChatHistoryCache() }
        do { cache=try ChatHistoryCache.load(scope:scope) } catch { note="本机记录读取失败，可重新同步" }
        let stamp=generation
        polling=Task {
            while !Task.isCancelled && stamp==generation {
                await refresh(device)
                do { try await Task.sleep(nanoseconds: device.sending || device.status?.busy == true ? 800_000_000 : 2_000_000_000) } catch { return }
            }
        }
    }
    func stop() { generation=UUID();polling?.cancel();polling=nil;loading=false }
    func refresh(_ device: DevicePilotStore, older: Bool = false) async {
        guard !loading else { return }
        loading=true;let stamp=generation
        defer { if stamp==generation { loading=false } }
        do {
            let page=try await device.chat(since:older ? 0 : cache.revision,before:older ? cache.turns.first?.position : nil)
            guard stamp==generation,!Task.isCancelled else { return }
            let actual=device.address+"|"+page.deviceId
            if actual != scope { scope=actual;cache=ChatHistoryCache() }
            if !older,page.turns.isEmpty,page.revision==cache.revision,page.reset != true { note="";return }
            cache.merge(page,older:older)
            try cache.save(scope:scope);UserDefaults.standard.set(scope,forKey:"chat.last-scope")
            note=""
        } catch { if stamp==generation { note=device.connected ? "记录同步暂不可用，已保留本机记录" : "离线记录" } }
    }
}
