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
    @State private var notificationMessage = ""

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
            SecureField("测试访问凭据", text: $config.token)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
            Text("仅用于测试")
                .font(AppFont.caption()).foregroundStyle(.secondary)
            #if DEBUG
            NavigationLink { DeviceLabView() } label: {
                MenuRow(icon: "antenna.radiowaves.left.and.right", title: "设备联调")
            }
            #endif
        }
        .card()
    }

    // MARK: 通知

    private var notifCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            CapLabel("通知")
            LabeledRow(title: "本地通知测试", note: "未开启")
            HStack {
                Text("系统通知授权:\(notifStatus)").font(AppFont.body(13)).foregroundStyle(.secondary)
                Spacer()
                Button("测试通知") { Task { await requestNotif() } }
                    .font(AppFont.caption()).foregroundStyle(T.mid)
            }
            if !notificationMessage.isEmpty {
                Text(notificationMessage)
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
        guard granted else {
            notificationMessage = "请在系统设置中允许通知"
            return
        }
        let content = UNMutableNotificationContent()
        content.title = "通知就绪"
        content.body = "这是一条本地测试通知。当前未开启自动内容提醒。"
        let req = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        do {
            try await UNUserNotificationCenter.current().add(req)
            notificationMessage = "已发送"
        } catch {
            notificationMessage = "发送失败，请重试"
        }
    }

    // MARK: 隐私

    private var privacyCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            LabeledRow(title: "蓝牙授权", note: "配网时申请，可在系统设置中管理")
            Divider()
            LabeledRow(title: "通知授权", note: "仅测试")
            Divider()
            LabeledRow(title: "数据与隐私", note: "请勿输入敏感信息")
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
