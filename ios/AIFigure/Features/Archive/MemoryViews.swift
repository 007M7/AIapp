import SwiftUI

/// 记忆面板(archive/memory):查看/编辑/删除/封存四操作(PRD 验收 #4)。
/// 用户主动删 = 硬删;系统淘汰 = 归档(「已淡忘」)。删除权口径终裁挂 Q-35。
struct MemoryPanelView: View {
    @EnvironmentObject private var env: AppEnv
    let character: FigureCharacter
    @ObservedObject private var config = ServerConfig.shared
    @StateObject private var remote = RemoteCollection<MemoryItem>()
    private var memories: [MemoryItem] { remote.items }
    @State private var showSealed = false
    @State private var confirmClear = false
    @State private var message = ""

    private var visible: [MemoryItem] {
        memories.filter { showSealed ? $0.isArchived : !$0.isArchived }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                PageHeader(title: "它记得的事",
                           subtitle: "\(visible.count) 条")
                Picker("视图", selection: $showSealed) {
                    Text("在记的").tag(false)
                    Text("已封存").tag(true)
                }
                .pickerStyle(.segmented)
                CollectionStatusCard(phase: remote.phase, emptyTitle: Copy.emptyMemoriesTitle,
                                     emptyNote: Copy.emptyMemoriesNote) { Task { await load() } }
                if remote.phase == .loaded && visible.isEmpty {
                    EmptyStateCard(title: showSealed ? "没有封存的记忆" : Copy.emptyMemoriesTitle,
                                   note: showSealed ? Copy.sealNote : Copy.emptyMemoriesNote)
                }
                ForEach(visible) { m in
                    memoryCard(m)
                }
                Button("按角色一键清空") { confirmClear = true }
                    .font(AppFont.caption()).foregroundStyle(.red)
                if !message.isEmpty { Text(message).font(AppFont.body(13)).foregroundStyle(.secondary) }
            }
            .padding(16)
        }
        .background(T.paper)
        .navigationTitle("记忆")
        .task(id: config.revision) { await load() }
        .refreshable { await load() }
        .alert("清空它的全部记忆?", isPresented: $confirmClear) {
            Button("清空", role: .destructive) { Task { await clear() } }
            Button("取消", role: .cancel) {}
        } message: {
            Text("按角色硬删,不可找回。确定的话,它就不记得这些事了。")
        }
    }

    private func load() async {
        await remote.load(config: config) { try await env.api.memories(characterId: character.id) }
    }

    private func clear() async {
        do {
            _ = try await env.api.clearMemories(characterId: character.id)
            await load()
            message = "已清空。"
        } catch { message = "没成功:\(error.localizedDescription)" }
    }

    private func memoryCard(_ m: MemoryItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(m.factText ?? "(空)").font(AppFont.headline(15)).foregroundStyle(T.ink)
            Text([m.category, m.createdAt].compactMap { $0 }.joined(separator: " · "))
                .font(AppFont.caption()).foregroundStyle(.secondary)
            HStack(spacing: 12) {
                NavigationLink { MemoryEditView(memory: m) { _ in
                    Task { await load() }
                } } label: { Text("编辑").font(AppFont.caption()).foregroundStyle(T.mid) }
                Button("封存") { Task { await setStatus(m, archived: true) } }
                    .font(AppFont.caption()).foregroundStyle(T.gold)
                Button("删除") { Task { await delete(m) } }
                    .font(AppFont.caption()).foregroundStyle(.red)
                Spacer()
            }
        }
        .card()
    }

    private func delete(_ m: MemoryItem) async {
        do {
            _ = try await env.api.deleteMemory(m.id)
            await load()
        } catch { message = "删除没成功:\(error.localizedDescription)" }
    }

    private func setStatus(_ m: MemoryItem, archived: Bool) async {
        do {
            _ = try await env.api.updateMemory(m.id, factText: m.factText ?? "",
                                                         status: archived ? "archived" : "active")
            await load()
        } catch {
            message = "封存没成功:\(error.localizedDescription)"
        }
    }
}

/// 单条记忆编辑(archive/memory-edit):改写/置顶由字段承载;删除为硬删
struct MemoryEditView: View {
    @EnvironmentObject private var env: AppEnv
    let memory: MemoryItem
    var onSaved: (MemoryItem) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var message = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                PageHeader(title: "编辑这条记忆")
                VStack(alignment: .leading, spacing: 8) {
                    CapLabel("它记下来的话")
                    TextEditor(text: $text)
                        .frame(minHeight: 100)
                        .font(AppFont.body())
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 10).fill(.white))
                }
                .card()
                PrimaryButton(title: "保存") { Task { await save() } }
                SecondaryButton(title: "删除(不可找回)") { Task { await remove() } }
                Text(Copy.memoryEditNote).font(AppFont.caption()).foregroundStyle(.secondary)
                if !message.isEmpty { Text(message).font(AppFont.body(13)).foregroundStyle(.secondary) }
            }
            .padding(16)
        }
        .background(T.paper)
        .navigationTitle("编辑记忆")
        .onAppear { text = memory.factText ?? "" }
    }

    private func save() async {
        do {
            let updated = try await env.api.updateMemory(memory.id, factText: text)
            onSaved(updated)
            dismiss()
        } catch { message = "保存没成功:\(error.localizedDescription)" }
    }

    private func remove() async {
        do {
            _ = try await env.api.deleteMemory(memory.id)
            dismiss()
        } catch { message = "删除没成功:\(error.localizedDescription)" }
    }
}
