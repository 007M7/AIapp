import SwiftUI

/// Tab3 社区(community/index):官方周更 + 精选角色包。
/// UGC M1 才开闸;本期仅官方内容(`14` §4.6),机审面为零。
struct CommunityView: View {
    @EnvironmentObject private var env: AppEnv
    @ObservedObject private var config = ServerConfig.shared
    @StateObject private var packList = RemoteCollection<PackItem>()
    @StateObject private var postList = RemoteCollection<CommunityPost>()
    private var packs: [PackItem] { packList.items }
    private var posts: [CommunityPost] { postList.items }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    CapLabel("最新动态").frame(maxWidth: .infinity, alignment: .leading)
                    CollectionStatusCard(phase: postList.phase, emptyTitle: "暂无动态", emptyNote: "") {
                        Task { await loadPosts() }
                    }
                    ForEach(posts) { post in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "person.crop.circle").foregroundStyle(T.mid)
                                Text(post.authorName ?? "官方").font(AppFont.caption()).foregroundStyle(.secondary)
                                Spacer()
                            }
                            Text(post.title ?? "").font(AppFont.headline(17)).foregroundStyle(T.ink)
                            if let summary = post.summary, !summary.isEmpty {
                                Text(summary).font(AppFont.body(14)).foregroundStyle(T.ink)
                            }
                            if let pack = packs.first(where: { $0.id == post.packId }) {
                                NavigationLink { PackDetailView(pack: pack) } label: {
                                    Label(pack.title ?? "查看内容", systemImage: "book")
                                        .font(AppFont.caption()).foregroundStyle(T.mid)
                                }
                            }
                        }.frame(maxWidth: .infinity, alignment: .leading).card()
                    }
                    sectionHeader("角色")
                    CollectionStatusCard(phase: packList.phase, emptyTitle: "暂无角色", emptyNote: "") {
                        Task { await loadPacks() }
                    }
                    ForEach(packs) { p in
                        NavigationLink { PackDetailView(pack: p) } label: { packCard(p) }.buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
            .background(T.paper)
            .navigationTitle("社区")
            .task(id: config.revision) { await load() }
            .refreshable { await load() }
        }
    }

    private func load() async {
        async let packs: Void = loadPacks()
        async let posts: Void = loadPosts()
        _ = await (packs, posts)
    }

    private func loadPacks() async {
        await packList.load(config: config) {
            try await env.api.packs().filter { $0.official == true }
        }
    }

    private func loadPosts() async {
        await postList.load(config: config) { try await env.api.posts().filter { $0.official == true } }
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
            Image(systemName: "chevron.right").foregroundStyle(.secondary)
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
