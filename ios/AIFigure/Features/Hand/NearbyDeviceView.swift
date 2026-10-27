import SwiftUI

struct NearbyDeviceView: View {
    @ObservedObject var nearby: NearbyDeviceStore
    @StateObject private var discovery = DeviceServiceDiscovery()
    @State private var ssid = ""
    @State private var password = ""
    @State private var volume = 75.0
    @State private var showPassword = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                if !nearby.connected {
                    Section("附近的手办") {
                        Button(nearby.scanning ? "重新搜索" : "搜索手办") { nearby.scan() }
                            .disabled(nearby.connecting)
                        ForEach(nearby.devices) { device in
                            Button { nearby.connect(device) } label: {
                                HStack { Label(device.name, systemImage: "figure.stand"); Spacer(); Text("连接").foregroundStyle(.secondary) }
                            }.disabled(nearby.connecting)
                        }
                        if nearby.devices.isEmpty { Text("请开启手机蓝牙，将手办放在附近并保持唤醒。需要主板固件 0.5.15 或更新版本。")
                            .font(.footnote).foregroundStyle(.secondary) }
                    }
                } else {
                    Section("蓝牙已连接") {
                        LabeledContent("设备", value: nearby.name)
                        LabeledContent("状态", value: nearby.status?.label ?? "正在读取")
                        LabeledContent("供电", value: nearby.status?.usb == true ? "外接电源" : "未检测到外接电源")
                        Button("让手办响一下") { nearby.command("identify") }.disabled(nearby.working)
                        VStack(alignment: .leading) {
                            Text("音量 \(Int(volume))%")
                            Slider(value: $volume, in: 0...100, step: 1) { editing in
                                if !editing { nearby.command("volume", fields: ["n": Int(volume)]) }
                            }.disabled(nearby.working)
                        }
                    }
                    Section("网络") {
                        LabeledContent("Wi-Fi", value: nearby.status?.wifi == true ? nearby.status?.ssid ?? "已连接" : "未连接")
                        LabeledContent("互动服务", value: nearby.status?.ready == true ? "已连接" : "未连接")
                        TextField("Wi-Fi／手机热点名称（2.4GHz）", text: $ssid)
                            .textInputAutocapitalization(.never).autocorrectionDisabled()
                        if showPassword { TextField("网络密码", text: $password).textInputAutocapitalization(.never).autocorrectionDisabled() }
                        else { SecureField("网络密码", text: $password).textInputAutocapitalization(.never).autocorrectionDisabled() }
                        Toggle("显示密码", isOn: $showPassword)
                        Button(nearby.working ? "正在处理…" : "连接这个网络") {
                            nearby.command("wifi", fields: ["s": ssid, "p": password]); password = ""
                        }.disabled(nearby.working || ssid.isEmpty || ssid.utf8.count > 32 || password.utf8.count > 63 || (!password.isEmpty && password.utf8.count < 8))
                        Text("可连接家中 Wi-Fi 或手机热点。新网络失败时保留原配置；联网后还需接通互动服务。")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                    Section("当前局域网的互动服务") {
                        Button(discovery.searching ? "重新寻找服务" : "寻找服务") { discovery.start() }
                        ForEach(discovery.services) { service in
                            Button(service.name) { nearby.command("server", fields: ["s": service.host, "n": service.port]) }
                                .disabled(nearby.working)
                        }
                        if discovery.searching && discovery.services.isEmpty {
                            Text("手机与运行服务的电脑需在同一可互通网络。当前 AI 服务仍需要电脑运行。")
                                .font(.footnote).foregroundStyle(.secondary)
                        }
                    }
                    Section {
                        Button("断开蓝牙", role: .destructive) { nearby.close() }
                        Text("授权保存在本机，再次连接无需填写凭据。断开蓝牙不会删除主板的 Wi-Fi 配置。")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }
                if !nearby.message.isEmpty { Section { Text(nearby.message).font(.subheadline) } }
            }
            .navigationTitle(nearby.connected ? "手办连接与网络" : "连接手办")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("完成") { dismiss() } } }
            .onAppear { if !nearby.connected && !nearby.connecting { nearby.scan() }; volume = Double(nearby.status?.volume ?? 75) }
            .onChange(of: nearby.status?.volume) { value in if let value { volume = Double(value) } }
            .onDisappear { discovery.stop() }
        }
    }
}
