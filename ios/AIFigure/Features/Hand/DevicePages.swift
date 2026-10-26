import SwiftUI

/// 按键说明(device/manual):两个动作,与包装卡、开箱第一句三处一致(`18` v1.2)。
struct DeviceManualView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                PageHeader(title: Copy.manualTitle, subtitle: Copy.manualIntro)
                ForEach(Copy.deviceActions) { a in
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: a.title == "按住说话" ? "waveform" : "hand.raised")
                            .font(.system(size: 28)).foregroundStyle(T.mid)
                        Text(a.title).font(AppFont.title(19)).foregroundStyle(T.ink)
                        Text(a.body).font(AppFont.body()).foregroundStyle(.secondary)
                    }
                    .card()
                }

            }
            .padding(16)
        }
        .background(T.paper)
        .navigationTitle("按键说明")
    }
}

/// 设备设置(device/settings):夜间静默(服务端策略)/ 解绑;无硬件控制项(设备侧 MVP1 冻结)。
struct DeviceSettingsView: View {
    @EnvironmentObject private var env: AppEnv
    let device: DeviceItem?
    @State private var confirmingUnbind = false
    @State private var message = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                PageHeader(title: "设备设置")
                VStack(spacing: 0) {
                    MenuRow(icon: "moon", title: Copy.nightQuietLabel, note: Copy.nightQuietNote)
                    Divider()
                    MenuRow(icon: "link.badge.checkmark", title: "解绑这台手办", note: "重新进入绑定流程", tint: .red)
                        .onTapGesture { confirmingUnbind = true }
                }
                .card()

                if !message.isEmpty { Text(message).font(AppFont.body(13)).foregroundStyle(.secondary) }
            }
            .padding(16)
        }
        .background(T.paper)
        .navigationTitle("设置")
        .alert("解绑这台手办?", isPresented: $confirmingUnbind) {
            Button("解绑", role: .destructive) { Task { await unbind() } }
            Button("取消", role: .cancel) {}
        } message: {
            Text("会解除账号与这台设备的绑定;它的记忆仍在你的角色档案里。")
        }
    }

    private func unbind() async {
        guard let id = device?.id else {
            message = "还没有已绑定的设备"
            return
        }
        do {
            _ = try await env.api.unbindDevice(id)
            message = "已解绑。"
        } catch {
            message = "解绑没成功:\(error.localizedDescription)"
        }
    }
}
