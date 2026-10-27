import SwiftUI

struct DeviceVolumeControl: View {
    @ObservedObject var device: DevicePilotStore
    @ObservedObject var nearby: NearbyDeviceStore
    @State private var value=75.0
    @State private var editing=false
    private var actual: Int? { nearby.connected ? nearby.status?.volume : device.volume }
    private var enabled: Bool { device.canSetVolume || (nearby.connected && !nearby.working) }
    var body: some View {
        VStack(spacing:4) {
            HStack(spacing:12) {
                Image(systemName:value == 0 ? "speaker.slash" : "speaker.wave.2").foregroundStyle(T.navy)
                Slider(value:$value,in:0...100,step:1) { active in
                    editing=active
                    if !active {
                        if device.canSetVolume { device.setVolume(Int(value)) }
                        else if nearby.connected { nearby.command("volume",fields:["n":Int(value)]) }
                    }
                }.disabled(!enabled)
                Text(actual == nil && !editing ? "—" : "\(Int(value))%")
                    .font(.caption.monospacedDigit()).frame(width:38)
            }
            if !device.volumeMessage.isEmpty { Text(device.volumeMessage).font(.caption).foregroundStyle(.secondary) }
        }
        .onAppear { value=Double(actual ?? 75) }
        .onChange(of:actual) { current in if !editing,let current { value=Double(current) } }
        .accessibilityLabel("手办音量")
    }
}

struct DeviceHoldToTalk: View {
    @ObservedObject var device: DevicePilotStore
    @ObservedObject var microphone: MobileVoiceRecorder
    @State private var held=false
    var body: some View {
        Text(microphone.active ? "松开发送" : device.interrupting ? "正在停止回答…" : microphone.preparing ? "准备麦克风…" : device.canInterrupt ? "按住打断并说话" : "按住说话")
            .font(.headline).frame(maxWidth:.infinity).padding(.vertical,15)
            .foregroundStyle(.white).background(T.navy,in:RoundedRectangle(cornerRadius:12))
            .opacity(device.canBeginVoice || microphone.active || microphone.preparing || device.interrupting ? 1 : 0.4)
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance:0).onChanged { _ in
                guard !held,device.canBeginVoice else { return }
                held=true
                Task {
                    let allowed=await device.prepareVoice()
                    guard held,allowed else { return }
                    await microphone.start()
                }
            }.onEnded { _ in held=false;microphone.finish() })
            .onDisappear { held=false;microphone.finish(cancel:true) }
            .accessibilityLabel(device.canInterrupt ? "按住打断当前回答并说话" : "按住说话，松开发送")
    }
}

struct DeviceChatView: View {
    @ObservedObject var device: DevicePilotStore
    @ObservedObject var nearby: NearbyDeviceStore
    @StateObject private var history=DeviceChatStore()
    @StateObject private var microphone=MobileVoiceRecorder()
    @State private var draft=""
    @State private var voiceInput=true
    @State private var volumeSheet=false
    @State private var followLatest=true
    @Environment(\.scenePhase) private var phase
    var body: some View {
        VStack(spacing:0) {
            ScrollViewReader { reader in
                ScrollView {
                    LazyVStack(spacing:18) {
                        if history.cache.hasOlder {
                            Button(history.loading ? "正在读取…" : "查看更早记录") {
                                followLatest=false
                                Task { await history.refresh(device,older:true) }
                            }.font(.footnote).disabled(history.loading)
                        }
                        if history.cache.turns.isEmpty {
                            Text("还没有聊天记录\n说句话，或发送一条消息")
                                .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.top,70)
                        }
                        ForEach(history.cache.turns) { turn in chatTurn(turn).id(turn.id) }
                        Color.clear.frame(height:1).id("latest")
                    }.padding(.horizontal,14).padding(.vertical,18)
                }
                .simultaneousGesture(DragGesture().onChanged { _ in followLatest=false })
                .onChange(of:history.cache.revision) { _ in if followLatest { reader.scrollTo("latest",anchor:.bottom) } }
                .overlay(alignment:.bottomTrailing) {
                    if !followLatest {
                        Button("回到最新") { followLatest=true;reader.scrollTo("latest",anchor:.bottom) }
                            .font(.caption).padding(9).background(.regularMaterial,in:Capsule()).padding(10)
                    }
                }
            }
            if !history.note.isEmpty { Text(history.note).font(.caption).foregroundStyle(.secondary).padding(6) }
            if !device.message.isEmpty { Text(device.message).font(.caption).foregroundStyle(.secondary).padding(6) }
            if !microphone.message.isEmpty { Text(microphone.message).font(.caption).foregroundStyle(.secondary).padding(6) }
            inputBar
        }
        .background(Color(white:0.94))
        .navigationTitle("小鲸").navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement:.principal) { VStack(spacing:2) {
                Text("小鲸").font(.headline)
                Text(device.stateTitle).font(.caption2).foregroundStyle(.secondary)
            } }
            ToolbarItem(placement:.navigationBarTrailing) {
                Button { volumeSheet=true } label: { Image(systemName:"speaker.wave.2") }.accessibilityLabel("调节手办音量")
            }
        }
        .sheet(isPresented:$volumeSheet) {
            VStack(alignment:.leading,spacing:24) {
                Text("手办音量").font(.title2.bold())
                DeviceVolumeControl(device:device,nearby:nearby)
                Button("完成") { volumeSheet=false }.frame(maxWidth:.infinity)
            }.padding(28).presentationDetents([.height(210)])
        }
        .task { history.start(device) }
        .onDisappear { history.stop();microphone.finish(cancel:true) }
        .onChange(of:phase) { phase in
            if phase == .active { history.start(device) }
            else if phase == .background { history.stop();microphone.finish(cancel:true) }
        }
        .onChange(of:microphone.ready) { audio in
            if let audio { followLatest=true;device.sendVoice(audio);microphone.ready=nil }
        }
    }
    private var inputBar: some View {
        HStack(alignment:.bottom,spacing:10) {
            Button { microphone.finish(cancel:true);voiceInput.toggle() } label: {
                Image(systemName:voiceInput ? "keyboard" : "waveform.circle").font(.title2).frame(width:30,height:48)
            }.accessibilityLabel(voiceInput ? "切换文字输入" : "切换语音输入")
            if voiceInput { DeviceHoldToTalk(device:device,microphone:microphone) }
            else {
                TextField("发送消息",text:$draft,axis:.vertical).lineLimit(1...4)
                    .padding(12).background(.white,in:RoundedRectangle(cornerRadius:10))
                Button("发送") { sendText() }.font(.subheadline.bold()).padding(.horizontal,13).padding(.vertical,14)
                    .foregroundStyle(.white).background(T.navy,in:RoundedRectangle(cornerRadius:10))
                    .disabled(!device.canBeginVoice || draft.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty || draft.count>1000)
            }
        }.padding(.horizontal,12).padding(.vertical,10).background(Color(white:0.98))
    }
    private func sendText() {
        let text=draft.trimmingCharacters(in:.whitespacesAndNewlines)
        guard !text.isEmpty,text.count<=1000 else { return }
        Task {
            guard await device.prepareVoice() else { return }
            followLatest=true;device.sendText(text)
            if draft.trimmingCharacters(in:.whitespacesAndNewlines)==text { draft="" }
        }
    }
    private func chatTurn(_ turn: LabChatTurn) -> some View {
        VStack(spacing:13) {
            Text(Date(timeIntervalSince1970:turn.created).formatted(date:.abbreviated,time:.shortened))
                .font(.caption2).foregroundStyle(.secondary)
            HStack(alignment:.top,spacing:9) {
                Spacer(minLength:45)
                VStack(alignment:.trailing,spacing:4) {
                    Text(turn.userText.isEmpty ? turn.userStatus=="transcribing" ? "语音识别中…" : "未识别到文字" : turn.userText)
                        .padding(12).background(Color(red:0.58,green:0.91,blue:0.43),in:RoundedRectangle(cornerRadius:9))
                        .textSelection(.enabled)
                    if turn.source != "phone_text" {
                        Label(turn.source=="device_voice" ? "手办语音" : "手机语音",systemImage:"waveform")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                }
                Image(systemName:"person.fill").font(.system(size:17)).frame(width:32,height:32).background(Color.white,in:RoundedRectangle(cornerRadius:7))
            }
            if !turn.assistantText.isEmpty || turn.userStatus=="final" {
                HStack(alignment:.top,spacing:9) {
                    Text("鲸").font(.subheadline.bold()).foregroundStyle(.white).frame(width:32,height:32).background(T.navy,in:RoundedRectangle(cornerRadius:7))
                    VStack(alignment:.leading,spacing:4) {
                        Text(turn.assistantText.isEmpty ? turn.assistantStatus=="waiting" ? "正在处理…" : "这次没有生成回复" : turn.assistantText)
                            .padding(12).background(.white,in:RoundedRectangle(cornerRadius:9)).textSelection(.enabled)
                        if !turn.assistantNote.isEmpty { Text(turn.assistantNote).font(.caption2).foregroundStyle(.secondary) }
                    }
                    Spacer(minLength:45)
                }
            }
        }.font(.body).foregroundStyle(Color.primary)
    }
}
