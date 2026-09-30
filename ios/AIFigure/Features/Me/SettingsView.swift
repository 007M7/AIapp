import SwiftUI
import UserNotifications

/// 通知与隐私 + 服务器设置(me/settings):
/// - 系统级推送是 App 端差异(PRD §3.3);自签免费证书无 APNs,本期只有**本地通知**(提醒类),
///   远程推送列入 App 通道二期(09 登记)。
/// - 隐私:对话原文不出域;分享卡默认脱敏(发言变「你」)。
struct SettingsView: View {
    @EnvironmentObject private var env: AppEnv
    @ObservedObject private var config = ServerConfig.shared
    @State private var notifStatus = "未询问"
    @State private var testSent = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                serverCard
                notifCard
                privacyCard
                aboutCard
            }
            .padding(16)
        }
        .background(T.paper)
        .navigationTitle("通知与隐私")
        .task { await refreshNotifStatus() }
    }

    // MARK: 服务器(开发期手动配置)

    private var serverCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            CapLabel("服务器")
            TextField("https://api.example.cn", text: $config.baseURL)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.URL)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            TextField("访问 token(开发期手动粘贴)", text: $config.token)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
            Text("App 走标准 TLS 的 api 域名(nginx SNI 分流后的那一侧);设备 PSK 域名与本 App 无关。")
                .font(AppFont.caption()).foregroundStyle(.secondary)
        }
        .card()
    }

    // MARK: 通知

    private var notifCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            CapLabel("通知")
            LabeledRow(title: "新内容提醒", note: "每周一次 · 不推广告")
            HStack {
                Text("系统通知授权:\(notifStatus)").font(AppFont.body(13)).foregroundStyle(.secondary)
                Spacer()
                Button("去授权") { Task { await requestNotif() } }
                    .font(AppFont.caption()).foregroundStyle(T.mid)
            }
            if testSent {
                Text("已发一条本地通知(从通知中心看)。远程推送要 APNs,自签证书不可用,列二期。")
                    .font(AppFont.caption()).foregroundStyle(.secondary)
            }
        }
        .card()
    }

    private func refreshNotifStatus() async {
        let s = await UNUserNotificationCenter.current().notificationSettings()
        notifStatus = switch s.authorizationStatus {
        case .authorized, .provisional: "已授权"
        case .denied: "已拒绝"
        case .notDetermined: "未询问"
        default: "未知"
        }
    }

    private func requestNotif() async {
        let granted = (try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .badge, .sound])) ?? false
        await refreshNotifStatus()
        guard granted else { return }
        let content = UNMutableNotificationContent()
        content.title = "通知就绪"
        content.body = "之后有官方周更时,每周提醒一次;不推广告。"
        let req = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        try? await UNUserNotificationCenter.current().add(req)
        testSent = true
    }

    // MARK: 隐私

    private var privacyCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Copy.privacyItems, id: \.title) { item in
                LabeledRow(title: item.title, note: item.note)
                Divider()
            }
            LabeledRow(title: "对话原文不出域", note: "只存你自己的服务器")
        }
        .card()
    }

    // MARK: 关于

    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            CapLabel("关于")
            LabeledRow(title: "版本", note: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0")
            NavigationLink { PromiseView() } label: {
                MenuRow(icon: "star", title: "服务连续性承诺")
            }
        }
        .card()
    }
}
