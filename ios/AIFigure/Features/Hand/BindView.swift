import SwiftUI

/// 绑定引导(device/bind):扫码 / 手动 SN;不强制,可先领"虚拟手办"占位(`19` §6.2)。
/// 认领端点:#3 POST /devices/claim(依赖 Q-52 出厂 SN+二维码)。
struct BindView: View {
    @EnvironmentObject private var env: AppEnv
    @State private var sn = ""
    @State private var claiming = false
    @State private var message = ""
    @State private var provisionOpen = false

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                PageHeader(title: Copy.bindTitle, subtitle: Copy.bindIntro)
                ForEach(Copy.bindOptions) { opt in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(opt.title).font(AppFont.headline()).foregroundStyle(T.ink)
                        Text(opt.body).font(AppFont.body(13)).foregroundStyle(.secondary)
                    }
                    .card()
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("手动输入 SN").font(AppFont.headline()).foregroundStyle(T.ink)
                    TextField("底座或说明书上的序列号", text: $sn)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                    PrimaryButton(title: claiming ? "认领中…" : "认领这只手办") { Task { await claim() } }
                    if !message.isEmpty {
                        Text(message).font(AppFont.body(13)).foregroundStyle(.secondary)
                    }
                }
                .card()
                NavigationLink { ProvisionView() } label: {
                    MenuRow(icon: "wifi", title: "BLE 配网", note: "把 WiFi 写给它")
                }
            }
            .padding(16)
        }
        .background(T.paper)
        .navigationTitle("绑定")
    }

    private func claim() async {
        claiming = true
        defer { claiming = false }
        do {
            _ = try await env.api.claimDevice(sn: sn.trimmingCharacters(in: .whitespaces))
            message = "认领成功;接下来做 BLE 配网,把 WiFi 发给它。"
        } catch {
            message = "认领没成功:\(error.localizedDescription)"
        }
    }
}
