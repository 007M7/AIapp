import SwiftUI

/// Tab1 手办 · 今天(`19` §4.2 hand/today,App 同构):
/// 状态卡 + 两动作入口 + 互动记录;首屏即"它今天"。
/// 纪律:无数值化显示(16 号「物感不是数值」)、无红点。
struct HandTodayView: View {
    @EnvironmentObject private var env: AppEnv
    @State private var device: DeviceItem?
    @State private var loadFailed = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    AIBadgeBar()
                    statusCard
                    NavigationLink { DeviceManualView() } label: { actionsCard }
                        .buttonStyle(.plain)
                    recentCard
                    NavigationLink { BindView() } label: {
                        MenuRow(icon: "qrcode", title: "绑定手办", note: device == nil ? "还没绑定" : "换一只")
                    }
                    NavigationLink { DeviceSettingsView(device: device) } label: {
                        MenuRow(icon: "gearshape", title: "设备设置")
                    }
                }
                .padding(16)
            }
            .background(T.paper)
            .navigationTitle("今天")
            .task { await load() }
            .refreshable { await load() }
        }
    }

    private func load() async {
        do {
            let list = try await env.api.devices()
            device = list.first
            loadFailed = false
        } catch {
            device = nil
            loadFailed = true
        }
    }

    // 状态卡:LED 呼吸镜像 + 两动作一句话
    private var statusCard: some View {
        VStack(spacing: 10) {
            BreathingOrb(lit: device?.online == true)
            Text(device?.online == true ? "它在桌上" : "它还没有连上")
                .font(AppFont.title(20))
                .foregroundStyle(T.ink)
            Text(device?.online == true
                 ? "按住头顶那颗按键,它就听你说;松手,它才开口"
                 : (loadFailed ? "配好服务器后,这里会亮起它的状态" : "绑定并配网后,它会出现在这里"))
                .font(AppFont.body(13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if let fw = device?.fw {
                Text("固件 \(fw)").font(AppFont.caption()).foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .card()
    }

    private var actionsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            CapLabel(Copy.manualTitle)
            ForEach(Copy.deviceActions, id: \.title) { a in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "hand.tap").foregroundStyle(T.mid)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(a.title).font(AppFont.headline(15)).foregroundStyle(T.ink)
                        Text(a.body).font(AppFont.body(13)).foregroundStyle(.secondary)
                    }
                }
            }
            Text("去按键说明 ›").font(AppFont.caption()).foregroundStyle(T.mid)
        }
        .card()
    }

    // 最近的相处:互动记录入口(数据走 #18 turns;未接服务器时显示引导)
    private var recentCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            CapLabel("最近的相处")
            if let id = device?.characterId {
                TurnListView(characterId: id)
            } else {
                Text("绑定手办后,这里会留下你们相处的痕迹")
                    .font(AppFont.body(13)).foregroundStyle(.secondary)
            }
        }
        .card()
    }
}

/// 互动记录(简版:#18 对话记录回看,带过期)
struct TurnListView: View {
    @EnvironmentObject private var env: AppEnv
    let characterId: String
    @State private var turns: [TurnItem] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if turns.isEmpty {
                Text("第一次对话之后,这里就会有记录").font(AppFont.body(13)).foregroundStyle(.secondary)
            } else {
                ForEach(turns.prefix(5)) { t in
                    HStack {
                        Text(t.createdAt ?? "").font(AppFont.caption()).foregroundStyle(.tertiary)
                        Text(t.text ?? "").font(AppFont.body(13)).foregroundStyle(T.ink).lineLimit(1)
                    }
                }
            }
        }
        .task { turns = (try? await env.api.turns(characterId: characterId)) ?? [] }
    }
}
