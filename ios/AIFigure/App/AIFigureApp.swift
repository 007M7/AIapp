import SwiftUI

@main
struct AIFigureApp: App {
    @StateObject private var env = AppEnv()

    var body: some Scene {
        WindowGroup {
            #if DEVICE_PILOT
            DevicePilotView()
                .environmentObject(env)
            #else
            RootTabView()
                .environmentObject(env)
                .tint(T.navy)
                .background(T.paper)
            #endif
        }
    }
}

/// 全局共享对象:API 客户端、回复播放器、开箱仪式进度(断点续做,`19` §6.1)
@MainActor
final class AppEnv: ObservableObject {
    let api = APIClient()
    let player = ReplyPlayer()

    @Published var showOnboarding: Bool

    init() {
        showOnboarding = !UserDefaults.standard.bool(forKey: "onboarding.done.v1")
    }

    func finishOnboarding() {
        UserDefaults.standard.set(true, forKey: "onboarding.done.v1")
        showOnboarding = false
    }
}
