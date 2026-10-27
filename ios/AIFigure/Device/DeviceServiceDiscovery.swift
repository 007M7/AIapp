import Foundation
import Combine
import Darwin

@MainActor
final class DeviceServiceDiscovery: NSObject, ObservableObject, NetServiceBrowserDelegate, NetServiceDelegate {
    struct Service: Identifiable { let id: String; let name: String; let host: String; let port: Int }
    @Published private(set) var services: [Service] = []
    @Published private(set) var searching = false
    private let browser = NetServiceBrowser()
    private var resolving: [NetService] = []
    override init() { super.init(); browser.delegate = self }
    func start() { stop(); services = []; searching = true; browser.searchForServices(ofType: "_aifigure._tcp.", inDomain: "local.") }
    func stop() { browser.stop(); resolving.forEach { $0.stop() }; resolving = []; searching = false }
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        resolving.append(service); service.delegate = self; service.resolve(withTimeout: 5)
    }
    func netServiceDidResolveAddress(_ sender: NetService) {
        for data in sender.addresses ?? [] {
            let host: String? = data.withUnsafeBytes { raw in
                guard let address = raw.baseAddress?.assumingMemoryBound(to: sockaddr.self), address.pointee.sa_family == sa_family_t(AF_INET) else { return nil }
                var name = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                guard getnameinfo(address, socklen_t(data.count), &name, socklen_t(name.count), nil, 0, NI_NUMERICHOST) == 0 else { return nil }
                return String(cString: name)
            }
            guard let host, (try? DeviceLabClient.validatedBase("http://\(host):\(sender.port)")) != nil else { continue }
            let txt = sender.txtRecordData().map(NetService.dictionary(fromTXTRecord:)) ?? [:]
            let voicePort = txt["voice_port"].flatMap { String(data: $0, encoding: .utf8) }.flatMap(Int.init) ?? 8766
            guard (1...65535).contains(voicePort) else { continue }
            let item = Service(id: sender.name + host, name: sender.name, host: host, port: voicePort)
            if !services.contains(where: { $0.id == item.id }) { services.append(item) }
        }
    }
    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) { services.removeAll { $0.name == service.name } }
    func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String: NSNumber]) { searching = false }
}
