#if DEBUG
import SwiftUI

@MainActor
struct DeviceLabView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var address = ""
    @State private var credential = ""
    @State private var client: DeviceLabClient?
    @State private var snapshot: LabDeviceStatus?
    @State private var operation: LabOperation?
    @State private var message = ""
    @State private var connecting = false
    @State private var sending = false
    @State private var uncertain = false
    @State private var generation = UUID()
    @State private var polling: Task<Void, Never>?
    @State private var submission: Task<Void, Never>?

    var body: some View {
        Form {
            Section("执行服务器") {
                TextField("http://电脑IP:8795", text: $address)
                    .keyboardType(.URL).textInputAutocapitalization(.never).autocorrectionDisabled()
                    .disabled(client != nil)
                if client == nil {
                    SecureField("联调凭据", text: $credential).textInputAutocapitalization(.never)
                    Button(connecting ? "连接中…" : "连接") { submission = Task { await connect() } }
                        .disabled(connecting)
                } else {
                    Button("断开", role: .destructive) { disconnect() }
                }
            }
            if let state = snapshot {
                Section("设备") {
                    LabeledContent("设备", value: state.deviceId)
                    LabeledContent("连接", value: state.deviceOnline ? "已连接" : "未连接")
                    LabeledContent("固件", value: state.firmware.isEmpty ? "未知" : state.firmware)
                    LabeledContent("状态", value: state.telemetry?.state ?? "未知")
                    LabeledContent("供电", value: powerLabel(state.telemetry))
                    LabeledContent("电压采样", value: voltageLabel(state.telemetry))
                    LabeledContent("电量／充电状态", value: "未知")
                    Button(sending ? "等待设备…" : "识别设备") { identify() }
                        .disabled(!state.canIdentify || sending || uncertain)
                    if !state.telemetryFresh { Text("等待最新状态").foregroundStyle(.secondary) }
                }
            }
            if let result = operation {
                Section("执行结果") {
                    Text(result.label)
                    Text(result.id).font(.caption).foregroundStyle(.secondary).textSelection(.enabled)
                }
            }
            if !message.isEmpty { Section { Text(message).foregroundStyle(.red) } }
        }
        .navigationTitle("设备联调")
        .onDisappear { disconnect() }
        .onChange(of: scenePhase) { phase in
            if phase == .active { startPolling() }
            else { polling?.cancel() }
        }
    }

    private func powerLabel(_ telemetry: LabTelemetry?) -> String {
        guard let telemetry else { return "未知" }
        return telemetry.usbPresent ? "USB 已接入" : "未检测到 USB"
    }
    private func voltageLabel(_ telemetry: LabTelemetry?) -> String {
        guard let telemetry, telemetry.batteryMv >= 0 else { return "未知" }
        return String(format: "%.2f V · 未校验", Double(telemetry.batteryMv) / 1000)
    }
    private func disconnect() {
        generation = UUID()
        polling?.cancel(); submission?.cancel()
        polling = nil; submission = nil; client = nil
        credential = ""; snapshot = nil; operation = nil
        connecting = false; sending = false; uncertain = false
    }
    private func connect() async {
        guard !connecting else { return }
        connecting = true; message = ""
        let identity = UUID(); generation = identity
        defer { if generation == identity { connecting = false } }
        do {
            let connected = try DeviceLabClient(address: address, token: credential)
            let value = try await connected.status()
            guard generation == identity, !Task.isCancelled else { return }
            client = connected; credential = ""; snapshot = value
            startPolling()
        } catch {
            if generation == identity { message = "连接失败，请检查地址、网络和联调凭据" }
        }
    }
    private func startPolling() {
        polling?.cancel()
        guard let connected = client else { return }
        let identity = generation
        polling = Task {
            while !Task.isCancelled && generation == identity {
                do {
                    let state = try await connected.status()
                    guard !Task.isCancelled, generation == identity else { return }
                    snapshot = state
                    if let id = operation?.id ?? state.pendingOperationId {
                        let result = try await connected.operation(id)
                        guard !Task.isCancelled, generation == identity else { return }
                        operation = result; sending = result.waiting
                    }
                    message = ""
                } catch is CancellationError { return }
                catch {
                    guard !Task.isCancelled, generation == identity else { return }
                    snapshot = nil
                    message = "读取失败，正在等待服务器恢复"
                    if let failure = error as? LabClientError, [401, 403].contains(failure.status ?? 0) {
                        disconnect(); message = "联调凭据无效，请重新连接"; return
                    }
                }
                do { try await Task.sleep(nanoseconds: 2_000_000_000) } catch { return }
            }
        }
    }
    private func identify() {
        guard let connected = client, snapshot?.canIdentify == true, !sending, !uncertain else { return }
        sending = true; message = ""
        let identity = generation
        let key = UUID()
        submission = Task {
            do {
                let result = try await connected.identify(key: key)
                guard !Task.isCancelled, generation == identity else { return }
                operation = result; sending = result.waiting
            } catch {
                guard !Task.isCancelled, generation == identity else { return }
                sending = false
                uncertain = (error as? LabClientError)?.status == nil
                message = uncertain ? "提交结果未确认，不会自动重试" : "请求未受理，请查看设备状态"
            }
        }
    }
}
#endif
