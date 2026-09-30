import Foundation
import AVFoundation

/// 播放文字回合(text-turn,`14` §5.4 #24)返回的回复音频。
/// 播放中可随时停 —— 打断 = 本地停播;V1 不承诺设备同步出声(设备同步播放是
/// 固件 G1 解锁后的增强;App 回合已写入角色上下文,可提示"按一下让它在设备上接这句")。
@MainActor
final class ReplyPlayer: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published private(set) var isPlaying = false
    private var player: AVAudioPlayer?

    /// 优先按完整音频容器(wav/mp3/m4a…)解;解不开就当裸 PCM16LE/16kHz 单声道,
    /// 补一个 WAV 头再放(响应字段以服务端实际落地为准,登记于 09 Q-87)。
    func play(data: Data) {
        stop()
        var payload = data
        if (try? AVAudioPlayer(data: payload)) == nil {
            payload = Self.wavWrapped(pcm: data)
            guard let p = try? AVAudioPlayer(data: payload), p.duration > 0 else { return }
            player = p
        } else if let p = try? AVAudioPlayer(data: payload) {
            player = p
        }
        guard let player, player.prepareToPlay() else { stop(); return }
        try? AVAudioSession.sharedInstance().setCategory(.playback, options: [.duckOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        player.delegate = self
        player.play()
        isPlaying = true
    }

    func play(url: URL) {
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data, !data.isEmpty else { return }
            Task { @MainActor in self?.play(data: data) }
        }.resume()
    }

    /// 播放中点击打断
    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.player = nil
            self.isPlaying = false
        }
    }

    /// 裸 PCM16LE / 16 kHz / 单声道 → WAV(RIFF)容器
    static func wavWrapped(pcm: Data) -> Data {
        var out = Data()
        let sampleRate: UInt32 = 16000, channels: UInt16 = 1, bits: UInt16 = 16
        let byteRate = sampleRate * UInt32(channels) * UInt32(bits / 8)
        func le32(_ v: UInt32) { withUnsafeBytes(of: v.littleEndian) { out.append(contentsOf: $0) } }
        func le16(_ v: UInt16) { withUnsafeBytes(of: v.littleEndian) { out.append(contentsOf: $0) } }
        out.append(contentsOf: Array("RIFF".utf8)); le32(UInt32(36 + pcm.count))
        out.append(contentsOf: Array("WAVE".utf8))
        out.append(contentsOf: Array("fmt ".utf8)); le32(16); le16(1); le16(channels)
        le32(sampleRate); le32(byteRate); le16(channels * bits / 8); le16(bits)
        out.append(contentsOf: Array("data".utf8)); le32(UInt32(pcm.count))
        out.append(pcm)
        return out
    }
}
