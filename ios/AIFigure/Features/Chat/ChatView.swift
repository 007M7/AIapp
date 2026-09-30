import SwiftUI

/// 文字回合(`14` §5.4 #24):App 发文字、收文本+音频;播放可随时打断(本地停播)。
/// V1 不承诺设备同步出声;回合已写入角色上下文,可提示按键接续。
struct ChatView: View {
    @EnvironmentObject private var env: AppEnv
    let character: FigureCharacter

    struct Bubble: Identifiable, Equatable {
        let id = UUID()
        var mine: Bool
        var text: String
    }

    @State private var input = ""
    @State private var bubbles: [Bubble] = []
    @State private var sending = false
    @FocusState private var inputFocus: Bool

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 10) {
                        if bubbles.isEmpty {
                            EmptyStateCard(title: "说第一句吧", note: "它会把你们聊过的事,记进「档案」的记忆里")
                                .padding(.top, 24)
                        }
                        ForEach(bubbles) { b in
                            HStack {
                                if b.mine { Spacer(minLength: 48) }
                                Text(b.text)
                                    .font(AppFont.body())
                                    .foregroundStyle(b.mine ? .white : T.ink)
                                    .padding(.horizontal, 14).padding(.vertical, 10)
                                    .background(RoundedRectangle(cornerRadius: 16)
                                        .fill(b.mine ? T.mid : T.card))
                                if !b.mine { Spacer(minLength: 48) }
                            }
                            .id(b.id)
                        }
                    }
                    .padding(16)
                }
                .onChange(of: bubbles) { _, list in
                    if let last = list.last { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
            if env.player.isPlaying {
                Button { env.player.stop() } label: {
                    Label("打断(停止播放)", systemImage: "stop.circle")
                        .font(AppFont.headline(14))
                        .foregroundStyle(T.gold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(T.card)
                }
            }
            HStack(spacing: 10) {
                TextField(Copy.chatSendHint, text: $input, axis: .vertical)
                    .font(AppFont.body())
                    .lineLimit(1...4)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 12).fill(T.card))
                    .focused($inputFocus)
                Button {
                    Task { await send() }
                } label: {
                    Image(systemName: sending ? "hourglass" : "arrow.up.circle.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(sending || input.isEmpty ? .tertiary : T.mid)
                }
                .disabled(sending || input.isEmpty)
            }
            .padding(.horizontal, 14).padding(.vertical, 8)
            Text(Copy.chatDeviceHint).font(AppFont.caption(11)).foregroundStyle(.tertiary)
        }
        .background(T.paper)
        .navigationTitle(character.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func send() async {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !sending else { return }
        sending = true
        input = ""
        bubbles.append(Bubble(mine: true, text: text))
        do {
            let result = try await env.api.textTurn(characterId: character.id, text: text)
            let reply = result.text ?? "(它好像没说话,再试一次?)"
            bubbles.append(Bubble(mine: false, text: reply))
            if let b64 = result.audioBase64, let data = Data(base64Encoded: b64), !data.isEmpty {
                env.player.play(data: data)
            } else if let urlText = result.audioUrl, let url = URL(string: urlText) {
                env.player.play(url: url)
            }
        } catch {
            bubbles.append(Bubble(mine: false, text: "没发出去:\(error.localizedDescription)"))
        }
        sending = false
        inputFocus = true
    }
}
