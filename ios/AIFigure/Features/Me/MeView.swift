import SwiftUI

/// Tab5 我的(me/index):账号/订阅位/承诺页/通知隐私/退出与删除。
/// 登录方式(微信 SDK / 手机号)待定(09 Q-88),MVP 显示未登录态与说明。
struct MeView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    AIBadgeBar()
                    accountCard
                    menuCard
                    NavigationLink { ExitView() } label: {
                        MenuRow(icon: "arrow.right.square", title: "退出与删除", tint: .red)
                    }
                    footer
                }
                .padding(16)
            }
            .background(T.paper)
            .navigationTitle("我的")
        }
    }

    private var accountCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.crop.circle").font(.system(size: 44)).foregroundStyle(T.mid)
            VStack(alignment: .leading, spacing: 2) {
                Text("还没有登录").font(AppFont.headline()).foregroundStyle(T.ink)
                Text("App 登录方式(微信 / 手机号)待定;开发期可在设置里手动填 token")
                    .font(AppFont.caption()).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .card()
    }

    private var menuCard: some View {
        VStack(spacing: 0) {
            MenuRow(icon: "gift", title: "订阅与兑换", note: "支付 V2 前悬置")
            Divider()
            NavigationLink { PromiseView() } label: {
                MenuRow(icon: "star", title: "服务连续性承诺")
            }
            Divider()
            NavigationLink { SettingsView() } label: {
                MenuRow(icon: "bell", title: "通知与隐私")
            }
            Divider()
            NavigationLink { SettingsView() } label: {
                MenuRow(icon: "gearshape", title: "设置(服务器)")
            }
        }
        .card()
    }

    private var footer: some View {
        VStack(spacing: 4) {
            Text("《用户协议》《隐私政策》").font(AppFont.caption()).foregroundStyle(T.mid)
            Text("互动对象为人工智能,不是真人").font(AppFont.caption(11)).foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
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
                    MenuRow(icon: "arrow.uturn.left", title: "退出登录", note: "不影响你在其它设备上的使用")
                    Divider()
                    MenuRow(icon: "trash", title: "删除这台手办与角色",
                            note: "会同时清除它在服务器上的记忆与档案", tint: .red)
                }
                .card()
                Text(Copy.exitNote).font(AppFont.body(13)).foregroundStyle(.secondary)
                if !message.isEmpty { Text(message).font(AppFont.body(13)).foregroundStyle(.secondary) }
            }
            .padding(16)
        }
        .background(T.paper)
        .navigationTitle("退出与删除")
        .onAppear {
            // 注销/删除的服务端端点在 14 §5.4 尚未定义,缺口已并入 09 Q-87;
            // 页面通道先行,文案不设阻拦。
            message = "数据删除的服务端端点随账号体系一起上线(09 Q-87);此处不留任何阻拦。"
        }
    }
}
