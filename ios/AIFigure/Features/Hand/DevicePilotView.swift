import SwiftUI

struct DevicePilotView: View {
    @StateObject private var device = DevicePilotStore()
    @StateObject private var microphone = MobileVoiceRecorder()
    @StateObject private var nearby = NearbyDeviceStore()
    @State private var showNearby = false
    @State private var holding = false
    @Environment(\.scenePhase) private var scenePhase
    @State private var setup = false
    @State private var scanner = false
    @State private var scanError = ""
    @State private var previewDetail = false
    @State private var previewChat = false

    init() {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        _setup = State(initialValue: arguments.contains("--preview-connect"))
        _previewDetail = State(initialValue: arguments.contains("--preview-device"))
        _showNearby = State(initialValue: arguments.contains("--preview-bluetooth"))
        _previewChat = State(initialValue: arguments.contains("--preview-chat"))
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
                        NavigationLink { DeviceChatView(device:device,nearby:nearby) } label: { Image(systemName:"bubble.left.and.bubble.right").font(.title3).padding(10) }
                            .accessibilityLabel("聊天与记录")
                        Button { showNearby = true } label: { Image(systemName: "link").font(.title3).padding(12) }
                            .accessibilityLabel("连接设置")
                    }
                    NavigationLink { detail } label: {
                        HStack {
                            Image(systemName: device.status?.deviceOnline == true ? "antenna.radiowaves.left.and.right" : "link")
                            Text(microphone.active ? "正在听" : connectionTitle).font(.subheadline.weight(.semibold))
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption)
                        }.padding(15).background(T.card, in: RoundedRectangle(cornerRadius: 18))
                    }.buttonStyle(.plain)
                    Image("XiaojingFront").resizable().scaledToFit()
                        .frame(maxWidth: .infinity).frame(height: 380)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 30))
                        .accessibilityLabel("小鲸")
                    DeviceVolumeControl(device:device,nearby:nearby).padding(12).background(T.card,in:RoundedRectangle(cornerRadius:14))
                    if !nearby.connected {
                        Button { showNearby = true } label: {
                            Label("连接附近的手办", systemImage: "antenna.radiowaves.left.and.right").frame(maxWidth: .infinity).padding(10)
                        }.buttonStyle(.borderedProminent)
                    } else {
                        HStack {
                            Button("响一下") { nearby.command("identify") }.disabled(nearby.working)
                            Spacer()
                            Button("音量与网络") { showNearby = true }
                        }.padding(14).background(T.card, in: RoundedRectangle(cornerRadius: 16))
                        if let status = nearby.status, !status.ready {
                            Text(status.wifi ? "蓝牙操作可用，接通互动服务后可说话" : "蓝牙操作可用，连接网络后开启语音互动")
                                .font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                    if device.connected {
                        DeviceHoldToTalk(device:device,microphone:microphone)
                        Button { device.identify() } label: {
                            Label(device.sending ? "等待手办回应" : "识别手办", systemImage: "waveform")
                                .frame(maxWidth: .infinity).padding(10)
                        }.disabled(!device.canIdentify || microphone.active || microphone.preparing)
                        Text("使用iPhone麦克风 · 手办播放回答")
                            .font(.footnote).foregroundStyle(.secondary).frame(maxWidth: .infinity)
                    }
                    if device.operation != nil {
                        Text(device.operationTitle).font(.subheadline).padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(T.card, in: RoundedRectangle(cornerRadius: 16))
                    }
                    if !device.message.isEmpty { Text(device.message).font(.footnote).foregroundStyle(.secondary) }
                    if !scanError.isEmpty { Text(scanError).font(.footnote).foregroundStyle(.secondary) }
                    if !microphone.message.isEmpty { Text(microphone.message).font(.footnote).foregroundStyle(.secondary) }
                    NavigationLink("聊天与记录") { DeviceChatView(device:device,nearby:nearby) }.frame(maxWidth:.infinity)
                    if !nearby.message.isEmpty { Text(nearby.message).font(.footnote).foregroundStyle(.secondary) }
                }.padding(22)
            }.background(T.paper).toolbar(.hidden, for: .navigationBar)
                .navigationDestination(isPresented: $previewDetail) { detail }
                .navigationDestination(isPresented: $previewChat) { DeviceChatView(device:device,nearby:nearby) }
                .refreshable { await device.refresh() }
        }
        .tint(T.navy)
        .task { device.resume(); nearby.resume() }
        .onChange(of: scenePhase) { phase in
            if phase == .active { device.resume(); nearby.resume() }
            else if phase == .background { holding = false; microphone.finish(cancel:true); device.pause(); nearby.close() }
        }
        .onChange(of:microphone.ready) { audio in if let audio { device.sendVoice(audio); microphone.ready = nil } }
        .onReceive(nearby.$gateway) { code in
            guard let code, !device.connecting,
                  !device.connected || device.address != code.server else { return }
            Task { await device.importCode(code) }
        }
        .sheet(isPresented: $showNearby) { NearbyDeviceView(nearby: nearby) }
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

    private var connectionTitle: String {
        if nearby.connected {
            if nearby.status?.ready == true && !device.connected { return "手办已联网 · 手机服务待连接" }
            return nearby.status?.label ?? "蓝牙已连接 · 等待状态"
        }
        return device.stateTitle
    }
    private var detail: some View {
        List {
            Section("当前状态") {
                LabeledContent("手办", value: connectionTitle)
                LabeledContent("蓝牙", value: nearby.connected ? "已连接" : "未连接")
                LabeledContent("Wi-Fi", value: nearby.status.map { $0.wifi ? $0.ssid : "未连接" } ?? "等待主板状态")
                LabeledContent("供电", value: nearby.status.map { $0.usb ? "外接电源" : "未检测到外接电源" } ?? device.powerTitle)
                LabeledContent("待机", value: device.status?.powerMode == "desktop_online" ? "接电在线待机" : device.status?.powerMode == "battery_saving" ? "电池省电" : "等待状态更新")
                LabeledContent("电量", value: "暂不可用")
                LabeledContent("最后状态更新", value: nearby.lastRead?.formatted(date: .omitted, time: .standard) ?? device.lastContact)
                if device.operation != nil { Text(device.operationTitle) }
                if !device.message.isEmpty { Text(device.message).foregroundStyle(.secondary) }
                Button("刷新状态") { Task { await nearby.refresh(); await device.refresh() } }
            }
            Section("连接") {
                Button("蓝牙、音量与网络") { showNearby = true }
                Button("高级调试连接") { setup = true }
                if device.connected { Button("断开并清除连接", role: .destructive) { device.disconnect() } }
            }
            Section("帮助信息") {
                LabeledContent("设备", value: device.status?.deviceId ?? "未连接")
                LabeledContent("固件", value: nearby.status?.firmware ?? device.status?.firmware ?? "未知")
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
                Section("调试工具") { Button("扫描调试连接码") { setup = false; scanner = true } }
            }.navigationTitle("连接设置")
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("完成") { setup = false } } }
        }
    }
}
