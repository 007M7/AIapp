import Foundation
import Combine
import AVFoundation

@MainActor final class MobileVoiceRecorder: ObservableObject {
    @Published private(set) var active = false
    @Published private(set) var preparing = false
    @Published private(set) var message = ""
    @Published var ready: Data?
    private var generation = UUID()
    private var recorder: AVAudioRecorder?
    private var file: URL?
    private var timeout: Task<Void,Never>?

    func start() async {
        guard !active, !preparing else { return }
        generation = UUID(); let stamp = generation
        preparing = true; message = ""; ready = nil
        defer { if generation == stamp { preparing = false } }
        let allowed = await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { continuation.resume(returning: $0) }
        }
        guard generation == stamp else { return }
        guard allowed else { message = "请在系统设置中允许麦克风访问"; return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement)
            try session.setActive(true)
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".wav")
            file = url
            recorder = try AVAudioRecorder(url: url, settings: [AVFormatIDKey:kAudioFormatLinearPCM,
                AVSampleRateKey:16000, AVNumberOfChannelsKey:1, AVLinearPCMBitDepthKey:16,
                AVLinearPCMIsBigEndianKey:false, AVLinearPCMIsFloatKey:false])
            guard recorder?.record() == true else { throw LabClientError(status: nil, message: "麦克风暂不可用") }
            active = true
            timeout = Task { [weak self] in
                do { try await Task.sleep(nanoseconds:30_000_000_000) } catch { return }
                self?.finish()
            }
        } catch { message = "麦克风暂不可用，请重试"; cleanup() }
    }
    func finish(cancel: Bool = false) {
        generation = UUID(); preparing = false; timeout?.cancel(); timeout = nil
        guard active else { return }
        active = false; recorder?.stop()
        defer { cleanup() }
        guard !cancel else { message = "录音已取消"; return }
        do {
            guard let file else { return }
            let wav = try Data(contentsOf:file)
            guard wav.count >= 44, String(data:wav.prefix(4), encoding:.ascii) == "RIFF" else { throw CocoaError(.fileReadCorruptFile) }
            var offset = 12
            while offset + 8 <= wav.count {
                let name = String(data:wav[offset..<offset+4], encoding:.ascii)
                let length = (0..<4).reduce(0) { $0 | (Int(wav[offset+4+$1]) << ($1*8)) }
                guard length <= wav.count-offset-8 else { break }
                if name == "data" {
                    guard (16000...960000).contains(length), length % 2 == 0 else { message = "请按住录制0.5至30秒语音"; return }
                    ready = wav.subdata(in:offset+8..<offset+8+length); return
                }
                offset += 8 + length + length%2
            }
            throw CocoaError(.fileReadCorruptFile)
        } catch { message = "录音读取失败，请重试" }
    }
    private func cleanup() {
        recorder?.stop(); recorder = nil; active = false
        if let file { try? FileManager.default.removeItem(at:file) }; file = nil
        try? AVAudioSession.sharedInstance().setActive(false, options:.notifyOthersOnDeactivation)
    }
}
