import SwiftUI
import WebKit
import Combine

@MainActor final class LivingRoomController: ObservableObject {
    let device = DevicePilotStore()
    let nearby = NearbyDeviceStore()
    let microphone = MobileVoiceRecorder()
    let volumeBridge = SystemVolumeBridge()
    let history = DeviceChatStore()
    @Published var showDevice = false
    weak var webView: WKWebView?
    private var subscriptions = Set<AnyCancellable>()
    private var held = false
    private var pressID = UUID()
    private var started = false
    private struct PendingText: Codable { let text: String; let created: Date }
    private var pendingText: PendingText?
    private var pendingFile: URL? {
        guard let root = try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true) else { return nil }
        return root.appendingPathComponent("living-room-pending-text.json")
    }
    private func savePending(_ pending: PendingText) -> Bool {
        guard let file = pendingFile, let data = try? JSONEncoder().encode(pending) else { return false }
        do { try data.write(to: file, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication]); pendingText = pending; return true }
        catch { return false }
    }
    private func clearPending() {
        if let file = pendingFile { try? FileManager.default.removeItem(at: file) }
        pendingText = nil
    }

    init() {
        device.objectWillChange.sink { [weak self] _ in self?.scheduleUpdate() }.store(in: &subscriptions)
        nearby.objectWillChange.sink { [weak self] _ in self?.scheduleUpdate() }.store(in: &subscriptions)
        microphone.objectWillChange.sink { [weak self] _ in self?.scheduleUpdate() }.store(in: &subscriptions)
        history.objectWillChange.sink { [weak self] _ in self?.scheduleUpdate() }.store(in: &subscriptions)
        microphone.$ready.compactMap { $0 }.sink { [weak self] data in
            guard let self else { return }
            self.device.sendVoice(data); self.microphone.ready = nil
        }.store(in: &subscriptions)
        nearby.$gateway.compactMap { $0 }.sink { [weak self] code in
            guard let self, !self.device.connecting,
                  !self.device.connected || self.device.address != code.server else { return }
            Task { await self.device.importCode(code) }
        }.store(in: &subscriptions)
    }
    func start() {
        guard !started else { return }; started = true
        if let file = pendingFile, let data = try? Data(contentsOf: file) { pendingText = try? JSONDecoder().decode(PendingText.self, from: data) }
        device.resume(); nearby.resume(); history.start(device)
        volumeBridge.configure(device: device, nearby: nearby); volumeBridge.setForeground(true)
    }
    func setActive(_ active: Bool) {
        volumeBridge.setForeground(active)
        if active { device.resume(); nearby.resume(); history.start(device); scheduleUpdate() }
        else { held = false; pressID = UUID(); microphone.finish(cancel: true); history.stop(); device.pause(); nearby.close() }
    }
    private func scheduleUpdate() { DispatchQueue.main.async { [weak self] in self?.publish() } }
    func publish() {
        volumeBridge.configure(device: device, nearby: nearby)
        let encoder = JSONEncoder()
        guard let turns = try? encoder.encode(history.cache.turns),
              let rows = try? JSONSerialization.jsonObject(with: turns) else { return }
        if let pending = pendingText, history.cache.turns.contains(where: { $0.source == "phone_text" && $0.userText == pending.text && $0.created >= pending.created.timeIntervalSince1970 - 5 }) {
            clearPending(); webView?.evaluateJavaScript("window.pilotTextAccepted && window.pilotTextAccepted()")
        }
        let message = !microphone.message.isEmpty ? microphone.message : (!device.message.isEmpty ? device.message : nearby.message)
        let payload: [String: Any] = ["state": device.stateTitle, "connected": device.connected,
            "canTalk": device.canBeginVoice, "recording": microphone.active,
            "preparing": microphone.preparing || device.interrupting, "message": message,
            "turns": rows, "hasOlder": history.cache.hasOlder, "historyNote": history.note, "pendingText": pendingText?.text ?? ""]
        guard let data = try? JSONSerialization.data(withJSONObject: payload),
              let json = String(data: data, encoding: .utf8) else { return }
        webView?.evaluateJavaScript("window.receivePilotState && window.receivePilotState(\(json))")
    }
    func receive(_ message: [String: Any]) {
        guard let type = message["type"] as? String else { return }
        switch type {
        case "ready": start(); publish()
        case "settings": showDevice = true
        case "history": Task { await history.refresh(device, older: true) }
        case "dismiss-pending": clearPending(); publish()
        case "voice-start":
            guard !held else { return }
            guard device.canBeginVoice else { publish(); return }
            held = true; let stamp = UUID(); pressID = stamp
            Task {
                let allowed = await device.prepareVoice()
                guard held, stamp == pressID, allowed else { return }
                volumeBridge.setRecording(true); await microphone.start()
                if !held || stamp != pressID { microphone.finish(cancel: true) }
                volumeBridge.setRecording(microphone.active || microphone.preparing)
                publish()
            }
        case "voice-end":
            guard held else { return }; held = false; pressID = UUID()
            microphone.finish(); volumeBridge.setRecording(false); publish()
        case "voice-cancel":
            held = false; pressID = UUID(); microphone.finish(cancel: true); volumeBridge.setRecording(false); publish()
        case "text":
            guard let value = message["text"] as? String else { return }
            let text = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty, text.count <= 1000, device.canBeginVoice else { publish(); return }
            guard pendingText == nil else {
                webView?.evaluateJavaScript("window.pilotPendingMessage && window.pilotPendingMessage()")
                return
            }
            guard savePending(PendingText(text: text, created: Date())) else {
                webView?.evaluateJavaScript("window.pilotLocalSaveFailed && window.pilotLocalSaveFailed()")
                return
            }
            Task {
                guard await device.prepareVoice() else { publish(); return }
                device.sendText(text); publish()
            }
        default: break
        }
    }
}

struct LivingRoomPilotView: View {
    @StateObject private var pilot = LivingRoomController()
    @Environment(\.scenePhase) private var phase
    var body: some View {
        LivingRoomWebView(pilot: pilot).ignoresSafeArea()
            .sheet(isPresented: $pilot.showDevice) { NearbyDeviceView(nearby: pilot.nearby) }
            .onAppear { pilot.start() }
            .onChange(of: phase) { value in pilot.setActive(value == .active) }
    }
}

struct LivingRoomWebView: UIViewRepresentable {
    @ObservedObject var pilot: LivingRoomController
    final class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
        let pilot: LivingRoomController
        init(_ pilot: LivingRoomController) { self.pilot = pilot }
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.frameInfo.isMainFrame, message.frameInfo.request.url?.scheme == "xiaojing",
                  message.frameInfo.request.url?.host == "scene", let body = message.body as? [String: Any] else { return }
            pilot.receive(body)
        }
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) { pilot.webView = webView; pilot.publish() }
    }
    func makeCoordinator() -> Coordinator { Coordinator(pilot) }
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.setURLSchemeHandler(LocalSceneScheme(), forURLScheme: "xiaojing")
        config.userContentController.add(context.coordinator, name: "pilot")
        config.userContentController.addUserScript(WKUserScript(source: "window.nativePilot = true;", injectionTime: .atDocumentStart, forMainFrameOnly: true))
        let view = WKWebView(frame: .zero, configuration: config)
        view.navigationDelegate = context.coordinator; view.isOpaque = false; view.scrollView.isScrollEnabled = false
        pilot.webView = view
        if let url = URL(string: "xiaojing://scene/index.html") { view.load(URLRequest(url: url)) }
        return view
    }
    func updateUIView(_ view: WKWebView, context: Context) {}
}

final class LocalSceneScheme: NSObject, WKURLSchemeHandler {
    func webView(_ webView: WKWebView, start task: WKURLSchemeTask) {
        guard let url = task.request.url, url.host == "scene",
              let root = Bundle.main.resourceURL?.appendingPathComponent("LivingRoomAssets", isDirectory: true) else {
            task.didFailWithError(URLError(.fileDoesNotExist)); return
        }
        let relative = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard !relative.isEmpty, !relative.split(separator: "/").contains("..") else {
            task.didFailWithError(URLError(.noPermissionsToReadFile)); return
        }
        let file = root.appendingPathComponent(relative).standardizedFileURL
        guard file.path.hasPrefix(root.standardizedFileURL.path + "/"), let data = try? Data(contentsOf: file) else {
            task.didFailWithError(URLError(.fileDoesNotExist)); return
        }
        let mime: String
        switch file.pathExtension.lowercased() {
        case "html": mime = "text/html"
        case "css": mime = "text/css"
        case "js", "mjs": mime = "text/javascript"
        case "png": mime = "image/png"
        case "webp": mime = "image/webp"
        default: mime = "application/octet-stream"
        }
        let response = URLResponse(url: url, mimeType: mime, expectedContentLength: data.count, textEncodingName: nil)
        task.didReceive(response); task.didReceive(data); task.didFinish()
    }
    func webView(_ webView: WKWebView, stop task: WKURLSchemeTask) {}
}
