import Foundation
import Combine
import AVFoundation

/// Observe the user's system media volume. iOS owns its HUD; never synthesize it,
/// set the system volume, or run silent audio to capture side buttons.
@MainActor final class SystemVolumeBridge: ObservableObject {
    @Published private(set) var message=""
    private weak var device: DevicePilotStore?
    private weak var nearby: NearbyDeviceStore?
    private var foreground=false
    private var recording=false
    private var observation: NSKeyValueObservation?
    private var routeObserver: NSObjectProtocol?
    private var activeSession=false
    private var ignoredUntil=Date.distantPast
    private var pending: Int?
    private var pendingAt=Date.distantPast
    private var delivery: Task<Void,Never>?

    func configure(device: DevicePilotStore, nearby: NearbyDeviceStore) {
        self.device=device;self.nearby=nearby;reconcile()
    }
    func setForeground(_ value: Bool) { foreground=value;reconcile() }
    func setRecording(_ value: Bool) { recording=value;reconcile() }
    private var connected: Bool { device?.status?.deviceOnline == true || nearby?.connected == true }
    private func reconcile() {
        guard foreground,connected,!recording else {
            observation?.invalidate();observation=nil
            if let routeObserver { NotificationCenter.default.removeObserver(routeObserver);self.routeObserver=nil }
            delivery?.cancel();delivery=nil;pending=nil
            // The recorder owns the session during capture; never deactivate it here.
            if activeSession && !recording { try? AVAudioSession.sharedInstance().setActive(false,options:.notifyOthersOnDeactivation) }
            activeSession=false
            return
        }
        guard observation == nil else { return }
        let session=AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback,mode:.default,options:.mixWithOthers)
            try session.setActive(true)
            activeSession=true;ignoredUntil=Date.distantPast
            observation=session.observe(\.outputVolume,options:[.old,.new]) { [weak self] _,change in
                guard let old=change.oldValue,let new=change.newValue else { return }
                Task { @MainActor [weak self] in self?.volumeChanged(old:old,new:new) }
            }
            routeObserver=NotificationCenter.default.addObserver(forName:AVAudioSession.routeChangeNotification,object:session,queue:.main) { [weak self] notification in
                let raw=(notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? NSNumber)?.uintValue ?? 0
                guard let reason=AVAudioSession.RouteChangeReason(rawValue:raw),
                      [.newDeviceAvailable,.oldDeviceUnavailable,.routeConfigurationChange,.override].contains(reason) else { return }
                Task { @MainActor [weak self] in self?.ignoredUntil=Date().addingTimeInterval(0.75);self?.pending=nil }
            }
        } catch { message="手机系统音量联动暂不可用，可在设备设置中调整" }
    }
    private func volumeChanged(old: Float,new: Float) {
        guard Date()>=ignoredUntil,connected,
              let target=SystemVolumePolicy.target(old:old,new:new,foreground:foreground,recording:recording) else { return }
        pending=target;pendingAt=Date();message=""
        guard delivery == nil else { return }
        delivery=Task { [weak self] in
            guard let self else { return }
            defer { self.delivery=nil }
            while !Task.isCancelled,self.foreground,self.connected,!self.recording,self.pending != nil {
                do { try await Task.sleep(nanoseconds:180_000_000) } catch { return }
                guard !Task.isCancelled,self.foreground,self.connected,!self.recording else { return }
                guard Date().timeIntervalSince(self.pendingAt)<3 else { self.pending=nil;self.message="手办音量暂不可调，请稍后再按音量键";return }
                if self.device?.volumeSending == true || self.nearby?.working == true { continue }
                guard let target=self.pending else { return }
                self.pending=nil
                if self.device?.canSetVolume == true { self.device?.setVolume(target) }
                else if self.nearby?.connected == true,self.nearby?.status?.state != "REC" { self.nearby?.command("volume",fields:["n":target]) }
                else { self.message="手办当前无法调节音量，请结束录音后重试";return }
                // Serialize writes while retaining only the most recent side-key value.
                for _ in 0..<40 {
                    if Task.isCancelled { return }
                    if self.device?.volumeSending != true && self.nearby?.working != true { break }
                    do { try await Task.sleep(nanoseconds:100_000_000) } catch { return }
                }
            }
        }
    }
}
