import SwiftUI

/// Tab3 社区(community/index):官方周更 + 精选角色包。
/// UGC M1 才开闸;本期仅官方内容(`14` §4.6),机审面为零。
struct CommunityView: View {
    @EnvironmentObject private var env: AppEnv
    @State private var packs: [PackItem] = []
    @State private var posts: [CommunityPost] = []
    @State private var configured = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    AIBadgeBar()
                    PageHeader(title: "社区", subtitle: "这里是角色包与故事的聚集地")
                    weeklyCard
                    if packs.isEmpty {
                        EmptyStateCard(title: Copy.emptyCommunityTitle, note: emptyNote)
                    } else {
                        sectionHeader("精选角色包")
                        ForEach(packs) { p in
                            NavigationLink { PackDetailView(pack: p) } label: { packCard(p) }
                                .buttonStyle(.plain)
                        }
                    }
                    if !posts.isEmpty {
                        sectionHeader("官方动态")
                        ForEach(posts) { post in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(post.title ?? "").font(AppFont.headline(15)).foregroundStyle(T.ink)
                                Text(post.summary ?? "").font(AppFont.body(13)).foregroundStyle(.secondary)
                            }
                            .card()
                        }
                    }
                }
                .padding(16)
            }
            .background(T.paper)
            .navigationTitle("社区")
            .task { await load() }
            .refreshable { await load() }
        }
    }

    private var emptyNote: String {
        configured ? Copy.emptyCommunityNote : "先在「我的 → 设置」里配好服务器"
    }

    private func load() async {
        configured = ServerConfig.shared.isConfigured
        packs = ((try? await env.api.packs()) ?? []).filter { $0.free == true || $0.official == true }
        posts = (try? await env.api.posts()) ?? []
    }

    /// 周更大卡
    private var weeklyCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(colors: [T.navy, T.mid], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(height: 120)
                VStack(alignment: .leading, spacing: 2) {
                    Text("官方周更").font(AppFont.caption()).foregroundStyle(T.ice)
                    Text("每周三更新;装载后它会在对话里接着讲")
                        .font(AppFont.headline(15)).foregroundStyle(.white)
                }
                .padding(12)
            }
        }
        .card(.clear)
    }

    private func sectionHeader(_ title: String) -> some View {
        CapLabel(title).frame(maxWidth: .infinity, alignment: .leading)
    }

    private func packCard(_ p: PackItem) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10).fill(T.card).frame(width: 56, height: 56)
                .overlay(Image(systemName: "book").foregroundStyle(T.mid))
            VStack(alignment: .leading, spacing: 2) {
                Text(p.title ?? "未命名").font(AppFont.headline(15)).foregroundStyle(T.ink)
                Text([p.author ?? "官方", p.summary].compactMap { $0 }.joined(separator: " · "))
                    .font(AppFont.caption()).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer()
            TagPill(p.priceText)
        }
        .card()
    }
}

/// 内容详情(community/detail):预渲染试听(#15 audition)+ 免费装载(#22 install)
struct PackDetailView: View {
    @EnvironmentObject private var env: AppEnv
    let pack: PackItem
    @State private var message = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                hero
                infoCard
                PrimaryButton(title: pack.free == false ? "装载(购买通道待开通)" : "免费装载到我的角色") {
                    Task { await install() }
                }
                .disabled(pack.free == false)   // 支付未开通(Q-20):付费商品先走兑换码
                SecondaryButton(title: "试听角色") { Task { await audition() } }
                if !message.isEmpty { Text(message).font(AppFont.body(13)).foregroundStyle(.secondary) }
            }
            .padding(16)
        }
        .background(T.paper)
        .navigationTitle(pack.title ?? "详情")
    }

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 18)
                .fill(LinearGradient(colors: [T.navy, T.blue], startPoint: .top, endPoint: .bottom))
                .frame(height: 150)
            VStack(alignment: .leading, spacing: 2) {
                Text(pack.title ?? "").font(AppFont.title(20)).foregroundStyle(.white)
                Text([pack.author ?? "官方", pack.episodes.map { "连载 \($0) 章" }].compactMap { $0 }
                    .joined(separator: " · "))
                    .font(AppFont.caption()).foregroundStyle(T.ice)
            }
            .padding(14)
        }
    }

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            LabeledRow(title: "作者 · \(pack.author ?? "官方")", note: pack.priceText)
            Text(pack.summary ?? "").font(AppFont.body(14)).foregroundStyle(T.ink)
        }
        .card()
    }

    private func install() async {
        do {
            _ = try await env.api.installPack(pack.id)
            message = "装好了;它已进你的收藏柜。"
        } catch { message = "装载没成功:\(error.localizedDescription)" }
    }

    private func audition() async {
        do {
            let result = try await env.api.audition(pack.id)
            if let b64 = result.audioBase64, let data = Data(base64Encoded: b64) {
                env.player.play(data: data)
            } else if let s = result.audioUrl, let url = URL(string: s) {
                env.player.play(url: url)
            } else {
                message = "这条还没有试听音频。"
            }
        } catch { message = "试听没成功:\(error.localizedDescription)" }
    }
}
