import SwiftUI

/// 5 Tab 对应五大域(`19` §3.1:手办|档案|社区|商店|我的,三端共用命名)。
/// 端差异仅登录/支付/推送三处,IA 不得再扩散(PRD §3.3)。
struct RootTabView: View {
    @EnvironmentObject private var env: AppEnv

    var body: some View {
        TabView {
            HandTodayView()
                .tabItem { Label("手办", systemImage: "figure.stand") }
            ArchiveHomeView()
                .tabItem { Label("档案", systemImage: "folder") }
            CommunityView()
                .tabItem { Label("社区", systemImage: "person.2") }
            StoreView()
                .tabItem { Label("商店", systemImage: "bag") }
            MeView()
                .tabItem { Label("我的", systemImage: "person.crop.circle") }
        }
        .fullScreenCover(isPresented: $env.showOnboarding) {
            OnboardingFlow()
                .environmentObject(env)
        }
    }
}

/// AI 身份标识:合规要求首页常驻(PRD §8)
struct AIBadgeBar: View {
    var body: some View {
        Label(Copy.aiBadge, systemImage: "sparkles")
            .font(AppFont.caption(11))
            .foregroundStyle(T.mid)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(Capsule().fill(T.card))
    }
}
