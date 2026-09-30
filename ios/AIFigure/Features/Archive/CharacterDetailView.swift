import SwiftUI

/// 角色详情(archive/character):圣经/音色/连载/相处事实 + 文字回合入口。
struct CharacterDetailView: View {
    @EnvironmentObject private var env: AppEnv
    let character: FigureCharacter
    @State private var fresh: FigureCharacter?

    private var c: FigureCharacter { fresh ?? character }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                hero
                nameCard
                if let tags = c.bibleTags, !tags.isEmpty { bibleCard(tags) }
                voiceCard
                factsCard
                PrimaryButton(title: "和它说几句", icon: "bubble.left.and.text.bubble.right") {
                    // 进入下方聊天
                }
                .simultaneousGesture(TapGesture()) // 占位:聊天入口在工具栏,见 toolbar
            }
            .padding(16)
        }
        .background(T.paper)
        .navigationTitle(c.displayName)
        .toolbar {
            NavigationLink { ChatView(character: c) } label: {
                Image(systemName: "bubble.left.and.text.bubble.right")
            }
        }
        .task { fresh = try? await env.api.character(c.id) }
    }

    private var hero: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(LinearGradient(colors: [T.card, T.ice.opacity(0.6)], startPoint: .top, endPoint: .bottom))
                .frame(height: 170)
            Image(systemName: "figure.wave").font(.system(size: 56)).foregroundStyle(T.mid.opacity(0.5))
        }
    }

    private var nameCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(c.displayName).font(AppFont.title(24)).foregroundStyle(T.ink)
            Text([c.packTitle, c.packVersion.map { "角色包 v\($0)" }, c.number]
                .compactMap { $0 }.joined(separator: " · "))
                .font(AppFont.body(13)).foregroundStyle(.secondary)
        }
        .card()
    }

    /// 角色圣经:叙事化标签;公开可查,改动提前公示(`14` D2 系)
    private func bibleCard(_ tags: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            CapLabel("角色圣经")
            FlowTags(tags)
            Text("圣经是公开可查的;任何改动都会提前公示,旧版本可以回滚。")
                .font(AppFont.caption()).foregroundStyle(.secondary)
        }
        .card()
    }

    private var voiceCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            CapLabel("音色")
            HStack {
                Text(c.voiceName ?? "基础音色").font(AppFont.body()).foregroundStyle(T.ink)
                Spacer()
                TagPill("已录制的基础音色永不更换")
            }
        }
        .card()
    }

    private var factsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            CapLabel("它记得的相处事实")
            if let facts = c.facts, !facts.isEmpty {
                ForEach(facts, id: \.self) { f in
                    Text("· \(f)").font(AppFont.body(14)).foregroundStyle(T.ink)
                }
            } else {
                Text(Copy.emptyMemoriesNote).font(AppFont.body(13)).foregroundStyle(.secondary)
            }
            NavigationLink { MemoryPanelView(character: c) } label: {
                Text("去「记忆」里查看全部 ›").font(AppFont.caption()).foregroundStyle(T.mid)
            }
        }
        .card()
    }
}

/// 简单换行标签组
struct FlowTags: View {
    let tags: [String]
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(tags, id: \.self) { t in TagPill(t) }
        }
    }
}
