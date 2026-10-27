import SwiftUI

/// Tab5 我的(me/index):账号/订阅位/承诺页/通知隐私/退出与删除。
/// 登录方式(微信 SDK / 手机号)待定(09 Q-88),MVP 显示未登录态与说明。
struct MeView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        Image(systemName: "person.crop.circle").font(.system(size: 44)).foregroundStyle(T.mid)
                        Text("我的").font(AppFont.headline())
                        Spacer()
                    }.card()
                    VStack(spacing: 0) {
                        NavigationLink { ArchiveHomeView() } label: { MenuRow(icon: "folder", title: "我的角色") }
                        Divider()
                        NavigationLink { BindView() } label: { MenuRow(icon: "qrcode", title: "连接手办") }
                    }.card()
                    NavigationLink { SettingsView() } label: { MenuRow(icon: "gearshape", title: "设置") }
                }.padding(16)
            }.background(T.paper).navigationTitle("我的")
        }
    }
}

/// 服务连续性承诺页(me/promise):与 17 §3.4 / 原型逐字一致(PRD 验收 #6)
struct PromiseView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                PageHeader(title: Copy.promisePageTitle, subtitle: Copy.promisePageIntro)
                VStack(alignment: .leading, spacing: 12) {
                    CapLabel(Copy.promiseSectionTitle)
                    ForEach(Copy.promises) { p in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("「\(p.title)」").font(AppFont.headline(16)).foregroundStyle(T.ink)
                            Text(p.body).font(AppFont.body(14)).foregroundStyle(.secondary)
                        }
                    }
                }
                .card()
                VStack(alignment: .leading, spacing: 8) {
                    CapLabel(Copy.stopServiceTitle)
                    Text(Copy.stopServiceItems).font(AppFont.headline(15)).foregroundStyle(T.gold)
                    ForEach(Copy.stopServiceNotes, id: \.self) { line in
                        Text(line).font(AppFont.body(13)).foregroundStyle(.secondary)
                    }
                }
                .card(Color(hex: 0xFFF8E6))
            }
            .padding(16)
        }
        .background(T.paper)
        .navigationTitle("承诺")
    }
}

/// 退出与删除(me/exit):一键通道,合规(15 §6.6 落地矩阵)
struct ExitView: View {
    @State private var message = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                PageHeader(title: Copy.exitTitle, subtitle: Copy.exitIntro)
                VStack(spacing: 0) {
                    MenuRow(icon: "arrow.uturn.left", title: "退出登录", note: "暂未开放")
                    Divider()
                    MenuRow(icon: "trash", title: "删除这台手办与角色",
                            note: "暂未开放", tint: .red)
                }
                .card()

                if !message.isEmpty { Text(message).font(AppFont.body(13)).foregroundStyle(.secondary) }
            }
            .padding(16)
        }
        .background(T.paper)
        .navigationTitle("退出与删除")
        .onAppear {
            // 注销/删除的服务端端点在 14 §5.4 尚未定义,缺口已并入 09 Q-87;
            // 页面通道先行,文案不设阻拦。
            message = "删除暂未开放"
        }
    }
}
