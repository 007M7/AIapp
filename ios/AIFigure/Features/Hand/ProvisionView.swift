import SwiftUI

/// BLE 配网(device/provision):扫描 → 连接 → Security 1 握手 → 写 WiFi → 查询联网。
/// 流程与加密与小程序 miniprogram/utils 完全同源(protocomm / Security 1,无 PoP)。
struct ProvisionView: View {
    @StateObject private var prov = Provisioner()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                PageHeader(title: "BLE 配网", subtitle: Copy.provisionIntro)
                stepList
                switch prov.stage {
                case .idle, .scanning:
                    scanList
                case .connecting:
                    progressCard("正在连接手办…", prov.stepLine)
                case .readyForWifi:
                    wifiForm
                case .provisioning:
                    progressCard("正在把 WiFi 发给手办", prov.stepLine)
                case .success(let ip):
                    successCard(ip)
                case .failed(let msg):
                    failCard(msg)
                }
                Text(Copy.provisionPrivacy).font(AppFont.caption()).foregroundStyle(.secondary)
            }
            .padding(16)
        }
        .background(T.paper)
        .navigationTitle("配网")
        .onDisappear { prov.close() }
    }

    // 步骤条:1 搜索 2 连接 3 握手 4 写入 5 联网(文案态,不做百分比)
    private var stepList: some View {
        VStack(alignment: .leading, spacing: 6) {
            step("1 搜索设备", done: stageOrder >= 1, active: stageOrder == 0)
            step("2 连接手办(蓝牙)", done: stageOrder >= 2, active: stageOrder == 1)
            step("3 建立加密握手", done: stageOrder >= 3, active: stageOrder == 2)
            step("4 写入 WiFi 名称与密码", done: stageOrder >= 4, active: stageOrder == 3)
            step("5 等它连上 WiFi", done: stageOrder >= 5, active: stageOrder == 4)
        }
        .card()
    }

    private var stageOrder: Int {
        switch prov.stage {
        case .idle, .scanning: return 0
        case .connecting: return 1
        case .readyForWifi: return 3
        case .provisioning: return 4
        case .success: return 5
        case .failed: return 0
        }
    }

    private func step(_ title: String, done: Bool, active: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: done ? "checkmark.circle.fill" : (active ? "circle.dotted" : "circle"))
                .foregroundStyle(done ? Color.green : (active ? T.mid : Color.secondary.opacity(0.4)))
            Text(title).font(AppFont.body(14)).foregroundStyle(done ? .secondary : T.ink)
        }
    }

    private var scanList: some View {
        VStack(spacing: 10) {
            if prov.devices.isEmpty {
                EmptyStateCard(title: "在找附近的手办", note: "确认它已通电,并进入配网模式(说明书里的按键组合)")
                if prov.stage != .scanning {
                    PrimaryButton(title: "开始搜索", icon: "dot.radiowaves.left.and.right") { prov.startScan() }
                } else {
                    SecondaryButton(title: "停止") { prov.stopScan() }
                }
            } else {
                ForEach(prov.devices) { d in
                    Button {
                        Task { await prov.connect(d) }
                    } label: {
                        HStack {
                            Image(systemName: "figure.stand").foregroundStyle(T.mid)
                            Text(d.name).font(AppFont.headline(15)).foregroundStyle(T.ink)
                            Spacer()
                            Text("\(d.rssi) dBm").font(AppFont.caption()).foregroundStyle(.tertiary)
                        }
                        .card()
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func progressCard(_ title: String, _ line: String) -> some View {
        VStack(spacing: 10) {
            BreathingOrb()
            Text(title).font(AppFont.headline())
            if !line.isEmpty { Text(line).font(AppFont.body(13)).foregroundStyle(.secondary) }
        }
        .frame(maxWidth: .infinity).card()
    }

    private var wifiForm: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("WiFi 名称与密码").font(AppFont.headline()).foregroundStyle(T.ink)
            TextField("WiFi 名称(SSID)", text: $prov.ssid).textFieldStyle(.roundedBorder).autocorrectionDisabled()
            SecureField("WiFi 密码", text: $prov.password).textFieldStyle(.roundedBorder)
            PrimaryButton(title: "发给手办", icon: "paperplane") { Task { await prov.sendWifi() } }
                .disabled(prov.ssid.isEmpty)
        }
        .card()
    }

    private func successCard(_ ip: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.circle").font(.system(size: 40)).foregroundStyle(.green)
            Text("连上了").font(AppFont.title(20))
            Text("它的地址:\(ip)\n回「今天」看看它的状态").font(AppFont.body(13))
                .foregroundStyle(.secondary).multilineTextAlignment(.center)
            PrimaryButton(title: "完成") { dismiss() }
        }
        .frame(maxWidth: .infinity).card()
    }

    private func failCard(_ msg: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle").font(.system(size: 32)).foregroundStyle(T.gold)
            Text("没成功").font(AppFont.headline())
            Text(msg).font(AppFont.body(13)).foregroundStyle(.secondary).multilineTextAlignment(.center)
            PrimaryButton(title: "重新开始") { prov.reset() }
        }
        .frame(maxWidth: .infinity).card()
    }
}
