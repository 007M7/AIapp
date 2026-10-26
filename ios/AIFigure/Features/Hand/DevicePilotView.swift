import SwiftUI

struct DevicePilotView: View {
    @StateObject private var device = DevicePilotStore()
    @Environment(\.scenePhase) private var scenePhase
    @State private var setup = false
    @State private var scanner = false
    @State private var scanError = ""
    @State private var previewDetail = false

    init() {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        _setup = State(initialValue: arguments.contains("--preview-connect"))
        _previewDetail = State(initialValue: arguments.contains("--preview-device"))
        #endif
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("小鲸").font(.system(size: 32, weight: .bold, design: .rounded))
                            Text("日常搭子").font(.subheadline).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button { setup = true } label: { Image(systemName: "link").font(.title3).padding(12) }
                            .accessibilityLabel("连接设置")
                    }
                    NavigationLink { detail } label: {
                        HStack {
                            Image(systemName: device.status?.deviceOnline == true ? "antenna.radiowaves.left.and.right" : "link")
                            Text(device.stateTitle).font(.subheadline.weight(.semibold))
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption)
                        }.padding(15).background(T.card, in: RoundedRectangle(cornerRadius: 18))
                    }.buttonStyle(.plain)
                    Image("XiaojingFront").resizable().scaledToFit()
                        .frame(maxWidth: .infinity).frame(height: 380)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 30))
                        .accessibilityLabel("小鲸")
                    if !device.connected {
                        Button { scanner = true } label: {
                            Label("扫码连接手办", systemImage: "qrcode.viewfinder").frame(maxWidth: .infinity).padding(10)
                        }.buttonStyle(.borderedProminent)
                        Button("手动连接") { setup = true }.frame(maxWidth: .infinity)
                    } else {
                        Button { device.identify() } label: {
                            Label(device.sending ? "等待手办回应" : "识别手办", systemImage: "waveform")
                                .frame(maxWidth: .infinity).padding(10)
                        }.buttonStyle(.borderedProminent).disabled(!device.canIdentify)
                        Text("按住手办按键说话，松开后听回应")
                            .font(.footnote).foregroundStyle(.secondary).frame(maxWidth: .infinity)
                    }
                    if let result = device.operation {
                        Text(result.label).font(.subheadline).padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(T.card, in: RoundedRectangle(cornerRadius: 16))
                    }
                    if !device.message.isEmpty { Text(device.message).font(.footnote).foregroundStyle(.secondary) }
                    if !scanError.isEmpty { Text(scanError).font(.footnote).foregroundStyle(.secondary) }
                }.padding(22)
            }.background(T.paper).toolbar(.hidden, for: .navigationBar)
                .navigationDestination(isPresented: $previewDetail) { detail }
                .refreshable { await device.refresh() }
        }
        .tint(T.navy)
        .task { device.resume() }
        .onChange(of: scenePhase) { phase in
            if phase == .active { device.resume() } else { device.pause() }
        }
        .sheet(isPresented: $setup) { setupView }
        .sheet(isPresented: $scanner) {
            NavigationStack {
                DeviceQRScanner { text in
                    scanner = false
                    do {
                        let code = try DeviceConnectionCode.parse(text)
                        Task { await device.importCode(code) }
                    } catch { scanError = "连接码无效，请使用电脑生成的手办连接码" }
                }
                .navigationTitle("扫描连接码")
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("取消") { scanner = false } } }
            }
        }
    }

    private var detail: some View {
        List {
            Section("当前状态") {
                LabeledContent("手办", value: device.stateTitle)
                LabeledContent("供电", value: device.powerTitle)
                LabeledContent("电量", value: "暂不可用")
                LabeledContent("最后状态更新", value: device.lastContact)
                if let result = device.operation { Text(result.label) }
                if !device.message.isEmpty { Text(device.message).foregroundStyle(.secondary) }
                Button("刷新状态") { Task { await device.refresh() } }
            }
            Section("连接") {
                Button("连接设置") { setup = true }
                NavigationLink("Wi-Fi配网") { ProvisionView() }
                if device.connected { Button("断开并清除连接", role: .destructive) { device.disconnect() } }
            }
            Section("帮助信息") {
                LabeledContent("设备", value: device.status?.deviceId ?? "未连接")
                LabeledContent("固件", value: device.status?.firmware ?? "未知")
                Text("这是局域网设备试用版。连接码保存在本机钥匙串，手机与手办需能访问同一台电脑服务。")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }.navigationTitle("我的手办").toolbar(.visible, for: .navigationBar)
    }

    private var setupView: some View {
        NavigationStack {
            Form {
                Section("连接手办") {
                    TextField("服务器地址", text: $device.address).keyboardType(.URL)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                        .disabled(device.connected || device.connecting)
                    SecureField("连接凭据", text: $device.credential)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                        .disabled(device.connected || device.connecting)
                    if device.connected {
                        Button("断开并重新设置", role: .destructive) { device.disconnect() }
                    } else {
                        Button(device.connecting ? "正在连接…" : "连接") {
                            Task { await device.connect(); if device.connected { setup = false } }
                        }.disabled(device.connecting)
                    }
                    if !device.message.isEmpty { Text(device.message).font(.footnote).foregroundStyle(.secondary) }
                }
                Section { Text("连接码由电脑上的手办服务提供。手机需接入同一局域网，并允许本地网络访问。") }
            }.navigationTitle("连接设置")
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("完成") { setup = false } } }
        }
    }
}
