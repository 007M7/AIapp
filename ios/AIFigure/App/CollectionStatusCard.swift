import SwiftUI

struct CollectionStatusCard: View {
    let phase: CollectionPhase
    let emptyTitle: String
    let emptyNote: String
    let retry: () -> Void

    var body: some View {
        Group {
            switch phase {
            case .idle, .loading:
                ProgressView("正在读取…").frame(maxWidth: .infinity).card()
            case .unconfigured:
                VStack(alignment: .leading, spacing: 10) {
                    Text("先连接你的档案").font(AppFont.headline()).foregroundStyle(T.ink)
                    Text("尚未连接")
                        .font(AppFont.body(13)).foregroundStyle(.secondary)
                    NavigationLink("设置连接") { SettingsView() }
                }.card()
            case .empty:
                EmptyStateCard(title: emptyTitle, note: emptyNote)
            case .failed(let message):
                VStack(alignment: .leading, spacing: 10) {
                    Text("暂时没有读到内容").font(AppFont.headline()).foregroundStyle(T.ink)
                    Text(message).font(AppFont.body(13)).foregroundStyle(.secondary)
                    Button("重新读取", action: retry)
                    NavigationLink("检查连接") { SettingsView() }
                }.card()
            case .loaded:
                EmptyView()
            }
        }
    }
}
