import SwiftUI

/// Tab2 档案 · 收藏册主视图(archive/index):角色卡网格 + 资产账入口。
/// "我的角色"≠设备管理页(PRD §4.3);空态引导"领养第一只手办"。
struct ArchiveHomeView: View {
    @EnvironmentObject private var env: AppEnv
    @ObservedObject private var config = ServerConfig.shared
    @StateObject private var remote = RemoteCollection<FigureCharacter>()
    private var characters: [FigureCharacter] { remote.items }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    CollectionStatusCard(phase: remote.phase, emptyTitle: Copy.emptyCharactersTitle,
                                         emptyNote: Copy.emptyCharactersNote) { Task { await load() } }
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                        ForEach(characters) { c in
                            NavigationLink { CharacterDetailView(character: c) } label: {
                                characterCard(c)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(16)
            }
            .background(T.paper)
            .navigationTitle("我的角色")
            .task(id: config.revision) { await load() }
            .refreshable { await load() }
        }
    }

    private func load() async {
        await remote.load(config: config) { try await env.api.characters() }
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
