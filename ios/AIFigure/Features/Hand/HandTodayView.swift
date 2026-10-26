import SwiftUI

/// Tab1 手办 · 今天(`19` §4.2 hand/today,App 同构):
/// 形象区域暂留空；互动记录在档案角色详情查看。
/// 纪律:无数值化显示(16 号「物感不是数值」)、无红点。
struct HandTodayView: View {
    @EnvironmentObject private var env: AppEnv
    @ObservedObject private var config = ServerConfig.shared
    @StateObject private var remote = RemoteCollection<DeviceItem>()
    private var device: DeviceItem? { remote.items.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    CollectionStatusCard(phase: remote.phase, emptyTitle: "把它放进你的收藏",
                                         emptyNote: "") { Task { await load() } }
                    Color.clear.frame(height: 210).accessibilityHidden(true)
                    NavigationLink { DeviceManualView() } label: { MenuRow(icon: "hand.tap", title: "按键说明") }
                        .buttonStyle(.plain)
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
            .task(id: config.revision) { await load() }
            .refreshable { await load() }
        }
    }

    private func load() async {
        await remote.load(config: config) { try await env.api.devices() }
    }

}

/// 互动记录(简版:#18 对话记录回看,带过期)
struct TurnListView: View {
    @EnvironmentObject private var env: AppEnv
    let characterId: String
    @ObservedObject private var config = ServerConfig.shared
    @StateObject private var remote = RemoteCollection<TurnItem>()

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            CollectionStatusCard(phase: remote.phase, emptyTitle: "从第一句话开始",
                                 emptyNote: "完成一次对话后，记录会出现在这里。") { Task { await load() } }
            ForEach(remote.items.prefix(5)) { t in
                HStack {
                    Text(t.createdAt ?? "").font(AppFont.caption()).foregroundStyle(.tertiary)
                    Text(t.text ?? "").font(AppFont.body(13)).foregroundStyle(T.ink).lineLimit(1)
                }
            }
        }
        .task(id: config.revision) { await load() }
    }

    private func load() async {
        await remote.load(config: config) { try await env.api.turns(characterId: characterId) }
    }
}
