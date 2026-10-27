import Foundation

let suite = "aiapp.draft-test.\(UUID().uuidString)"
let defaults = UserDefaults(suiteName: suite)!
defer { defaults.removePersistentDomain(forName: suite) }

assert(OnboardingDraft.read(from: defaults) == OnboardingDraft(step: 0, name: "小鲸", contractRead: false))
let saved = OnboardingDraft(step: 3, name: "小蓝", contractRead: true)
saved.save(to: defaults)
assert(OnboardingDraft.read(from: defaults) == saved)
defaults.set(99, forKey: "onboarding.step.v1")
assert(OnboardingDraft.read(from: defaults).step == 5)
defaults.set(-8, forKey: "onboarding.step.v1")
assert(OnboardingDraft.read(from: defaults).step == 0)
// 旧契约标记不能迁成正式签署，也不能替代本轮阅读标记。
defaults.set(true, forKey: "contract.signed.v1")
defaults.removeObject(forKey: "onboarding.contractRead.v1")
assert(!OnboardingDraft.read(from: defaults).contractRead)
print("开箱草稿：缺省、恢复、越界裁剪及旧契约隔离检查通过")
