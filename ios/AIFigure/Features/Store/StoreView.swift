import SwiftUI

/// Tab4 发现：沿用 packs 数据与 store 路由，按角色、故事、语音浏览。
struct StoreView: View {
    @EnvironmentObject private var env: AppEnv
    @ObservedObject private var config = ServerConfig.shared
    @StateObject private var remote = RemoteCollection<PackItem>()
    private var packs: [PackItem] { remote.items }
    @State private var category = "全部"

    private static let categories = ["全部", "角色", "故事", "语音"]

    private var filtered: [PackItem] {
        packs.filter { pack in
            if category == "全部" { return true }
            switch category {
            case "角色": return ["character", "角色"].contains(pack.category ?? "")
            case "故事": return ["event", "事件", "story", "故事"].contains(pack.category ?? "")
            case "语音": return ["voice", "语音"].contains(pack.category ?? "")
            default: return false
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    Picker("内容分类", selection: $category) {
                        ForEach(Self.categories, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    CollectionStatusCard(phase: remote.phase, emptyTitle: "暂无内容",
                                         emptyNote: "") { Task { await load() } }
                    if remote.phase == .loaded && filtered.isEmpty {
                        EmptyStateCard(title: "暂无内容", note: "")
                    }
                    ForEach(filtered) { p in
                        NavigationLink { PackDetailView(pack: p) } label: { packRow(p) }
                            .buttonStyle(.plain)
                    }
                    freeBanner

                }
                .padding(16)
            }
            .background(T.paper)
            .navigationTitle("发现")
            .task(id: config.revision) { await load() }
            .refreshable { await load() }
        }
    }

    private func load() async {
        await remote.load(config: config) { try await env.api.packs() }
    }

    /// 免费内容入口
    private var freeBanner: some View {
        NavigationLink { FreeZoneView() } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(Copy.freeZoneTitle).font(AppFont.headline(17)).foregroundStyle(T.gold)
                    Text(Copy.freeZoneBanner).font(AppFont.body(13)).foregroundStyle(T.ink)
                }
                Spacer()
                Text("看看 ›").font(AppFont.caption()).foregroundStyle(T.gold)
            }
            .card(Color(hex: 0xFFF8E6))
        }
        .buttonStyle(.plain)
    }

    private func packRow(_ p: PackItem) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10).fill(T.card).frame(width: 56, height: 56)
                .overlay(Image(systemName: icon(for: p.category)).foregroundStyle(T.mid))
            VStack(alignment: .leading, spacing: 2) {
                Text(p.title ?? "未命名").font(AppFont.headline(15)).foregroundStyle(T.ink)
                Text(p.summary ?? p.packLine).font(AppFont.caption()).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer()
            Image(systemName: "chevron.right").font(AppFont.caption()).foregroundStyle(.secondary)
        }
        .card()
    }

    private func icon(for category: String?) -> String {
        switch category {
        case "外观": return "tshirt"
        case "语音": return "waveform"
        case "事件": return "calendar"
        case "实物": return "gift"
        default: return "book"
        }
    }

    private var redeemCard: some View {
        NavigationLink { RedeemView() } label: {
            MenuRow(icon: "ticket", title: "兑换码", note: "实体卡 → 线上权益")
        }
    }
}

extension PackItem {
    /// "角色包 · 附 6 章连载" 风格的副行
    var packLine: String {
        [category.map { "\($0)包" }, episodes.map { "附 \($0) 章连载" }].compactMap { $0 }.joined(separator: " · ")
    }
}

/// 永久免费区(store/free):静态页,清单与边界逐字
struct FreeZoneView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                PageHeader(title: Copy.freeZoneTitle, subtitle: Copy.freeZoneIntro)
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Copy.freeZoneItems, id: \.self) { line in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark.circle").foregroundStyle(T.mid)
                            Text(line).font(AppFont.body(14)).foregroundStyle(T.ink)
                        }
                    }
                }
                .card()
                VStack(alignment: .leading, spacing: 6) {
                    CapLabel(Copy.paidIsMoreTitle)
                    Text(Copy.paidIsMoreBody).font(AppFont.body(14)).foregroundStyle(T.ink)
                }
                .card()
            }
            .padding(16)
        }
        .background(T.paper)
        .navigationTitle("免费区")
    }
}

/// 兑换码(store/redeem):实体 → 线上打通;服务端端点未定义(14 §5.4 刻意缺席支付),
/// 兑换接口随支付主体一起落地(Q-20),此处先收码并明确告知。
struct RedeemView: View {
    @State private var code = ""
    @State private var message = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                PageHeader(title: "兑换码")
                VStack(alignment: .leading, spacing: 10) {
                    TextField("输入卡上的码", text: $code)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.characters)
                    PrimaryButton(title: "兑换") { message = redeemNote }
                }
                .card()

                if !message.isEmpty { Text(message).font(AppFont.body(13)).foregroundStyle(.secondary) }
            }
            .padding(16)
        }
        .background(T.paper)
        .navigationTitle("兑换")
    }

    private var redeemNote: String {
        code.isEmpty ? "先输入卡上的码。" : "兑换暂未开放"
    }
}
