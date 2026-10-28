import SwiftUI
import WebKit

struct LivingRoomPilotView: View {
    @EnvironmentObject private var env: AppEnv
    @State private var showDevice = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            LivingRoomWebView().ignoresSafeArea()
            Button { showDevice = true } label: {
                Label("手办连接", systemImage: "link")
                    .font(.system(size: 12, weight: .medium))
                    .padding(.horizontal, 11).padding(.vertical, 7)
                    .background(.ultraThinMaterial, in: Capsule())
            }.padding(.leading, 16).padding(.top, 6)
        }
        .fullScreenCover(isPresented: $showDevice) {
            ZStack(alignment: .topTrailing) {
                DevicePilotView().environmentObject(env)
                Button("返回客厅") { showDevice = false }
                    .font(.footnote).padding(9)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.top, 6).padding(.trailing, 12)
            }
        }
    }
}

struct LivingRoomWebView: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.setURLSchemeHandler(LocalSceneScheme(), forURLScheme: "xiaojing")
        let view = WKWebView(frame: .zero, configuration: config)
        view.isOpaque = false
        view.scrollView.isScrollEnabled = false
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
