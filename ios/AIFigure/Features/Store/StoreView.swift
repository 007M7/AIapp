import SwiftUI

/// Tab4 商店(store/index):免费区横幅必须在首屏(消保委红线,PRD §4.3)
/// + 五架筛选 + 商品列表 + 兑换码入口。iOS 支付自由处理:购买通道待开通(Q-20),
/// 付费商品先走兑换码;不设占位接口(14 §5.4 刻意缺席)。
struct StoreView: View {
    @EnvironmentObject private var env: AppEnv
    @State private var packs: [PackItem] = []
    @State private var category = "角色"
    @State private var configured = true

    private static let categories = ["角色", "外观", "语音", "事件", "实物"]

    private var filtered: [PackItem] {
        packs.filter { $0.category == nil || $0.category == category }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    AIBadgeBar()
                    freeBanner
                    Picker("货架", selection: $category) {
                        ForEach(Self.categories, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    if filtered.isEmpty {
                        EmptyStateCard(title: Copy.emptyStoreTitle, note: emptyNote)
                    }
                    ForEach(filtered) { p in
                        NavigationLink { PackDetailView(pack: p) } label: { packRow(p) }
                            .buttonStyle(.plain)
                    }
                    redeemCard
                    Text(Copy.storeFooterNote).font(AppFont.caption()).foregroundStyle(.secondary)
                }
                .padding(16)
            }
            .background(T.paper)
            .navigationTitle("商店")
            .toolbar {
                NavigationLink { RedeemView() } label: { TagPill("兑换码") }
            }
            .task { await load() }
            .refreshable { await load() }
        }
    }

    private var emptyNote: String {
        configured ? Copy.emptyStoreNote : "先在「我的 → 设置」里配好服务器"
    }

    private func load() async {
        configured = ServerConfig.shared.isConfigured
        packs = (try? await env.api.packs()) ?? []
    }

    /// 首屏必现:永久免费区横幅
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
            VStack(alignment: .trailing, spacing: 2) {
                Text(p.priceText).font(AppFont.headline(14)).foregroundStyle(T.mid)
                Text(p.free == false ? "可兑换" : "免费")
                    .font(AppFont.caption(11)).foregroundStyle(.secondary)
            }
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
                Text(Copy.redeemIntro).font(AppFont.caption()).foregroundStyle(.secondary)
                if !message.isEmpty { Text(message).font(AppFont.body(13)).foregroundStyle(.secondary) }
            }
            .padding(16)
        }
        .background(T.paper)
        .navigationTitle("兑换")
    }

    private var redeemNote: String {
        code.isEmpty ? "先输入卡上的码。" : "兑换通道还没开通:兑换接口随支付主体一起上线(09 Q-30 依赖)。你的码不会作废。"
    }
}
