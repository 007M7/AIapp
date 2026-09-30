import SwiftUI

/// Tab2 档案 · 收藏册主视图(archive/index):角色卡网格 + 资产账入口。
/// "我的角色"≠设备管理页(PRD §4.3);空态引导"领养第一只手办"。
struct ArchiveHomeView: View {
    @EnvironmentObject private var env: AppEnv
    @State private var characters: [FigureCharacter] = []
    @State private var configured = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    AIBadgeBar()
                    if characters.isEmpty {
                        EmptyStateCard(title: Copy.emptyCharactersTitle, note: emptyNote)
                    }
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                        ForEach(characters) { c in
                            NavigationLink { CharacterDetailView(character: c) } label: {
                                characterCard(c)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    assetsCard
                }
                .padding(16)
            }
            .background(T.paper)
            .navigationTitle("我的角色")
            .task { await load() }
            .refreshable { await load() }
        }
    }

    private var emptyNote: String {
        configured ? Copy.emptyCharactersNote : "先在「我的 → 设置」里配好服务器,你的角色会出现在这里"
    }

    private func load() async {
        configured = ServerConfig.shared.isConfigured
        characters = (try? await env.api.characters()) ?? []
    }

    private func characterCard(_ c: FigureCharacter) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(LinearGradient(colors: [T.card, T.ice.opacity(0.5)],
                                                                       startPoint: .top, endPoint: .bottom))
                    .frame(height: 110)
                Image(systemName: "figure.wave").font(.system(size: 36)).foregroundStyle(T.mid.opacity(0.6))
            }
            Text(c.displayName).font(AppFont.headline(15)).foregroundStyle(T.ink)
            Text([c.number, c.adoptedAt].compactMap { $0 }.joined(separator: " · "))
                .font(AppFont.caption()).foregroundStyle(.secondary).lineLimit(1)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 14).fill(.white))
    }

    private var assetsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            CapLabel("资产账")
            NavigationLink { AssetsLedgerView(characters: characters) } label: {
                Text("全部 ›").font(AppFont.caption()).foregroundStyle(T.mid)
            }
            Text(Copy.assetsNote).font(AppFont.body(13)).foregroundStyle(.secondary)
        }
        .frame(alignment: .leading)
        .card()
    }
}

/// 资产账(archive/assets):只增不减,每一件都有来处
struct AssetsLedgerView: View {
    let characters: [FigureCharacter]
    var body: some View {
        List {
            Section {
                ForEach(characters) { c in
                    LabeledRow(title: "角色 · \(c.displayName)", note: c.adoptedAt ?? "领养")
                }
                LabeledRow(title: "编号 · \(characters.compactMap(\.number).first ?? "待颁发")", note: "与底座金属铭牌一致")
                LabeledRow(title: "契约 · 四件事", note: "签署后入账")
            } header: {
                Text(Copy.assetsIntro)
            } footer: {
                Text(Copy.assetsNote)
            }
        }
        .navigationTitle("资产账")
    }
}

struct LabeledRow: View {
    let title: String
    var note: String = ""
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(AppFont.body()).foregroundStyle(T.ink)
            if !note.isEmpty { Text(note).font(AppFont.caption()).foregroundStyle(.secondary) }
        }
        .padding(.vertical, 4)
    }
}
