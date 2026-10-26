import Foundation

/// 本机介绍进度和名字草稿，不代表服务端角色、入册或契约事实。
struct OnboardingDraft: Equatable {
    var step: Int
    var name: String
    var contractRead: Bool

    static func read(from defaults: UserDefaults = .standard) -> OnboardingDraft {
        OnboardingDraft(step: min(max(defaults.integer(forKey: "onboarding.step.v1"), 0), 5),
                        name: defaults.string(forKey: "onboarding.name.v1") ?? "小鲸",
                        contractRead: defaults.bool(forKey: "onboarding.contractRead.v1"))
    }

    func save(to defaults: UserDefaults = .standard) {
        defaults.set(min(max(step, 0), 5), forKey: "onboarding.step.v1")
        defaults.set(name, forKey: "onboarding.name.v1")
        defaults.set(contractRead, forKey: "onboarding.contractRead.v1")
    }
}
