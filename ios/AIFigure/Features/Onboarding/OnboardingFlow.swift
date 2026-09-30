import SwiftUI

/// 首次开箱仪式(`19` §6.1,六步):装备须知 → 绑定 → 认主 → 第一张角色卡 → 契约签署 → 完成。
/// 每一步均可跳过;断点续做(进度存 UserDefaults);不阻塞进入 Tab1。
struct OnboardingFlow: View {
    @EnvironmentObject private var env: AppEnv
    @State private var step = 0
    @State private var name = "小鲸"
    @State private var signed = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("第 \(step + 1) 步,共 6 步").font(AppFont.caption()).foregroundStyle(.secondary)
                Spacer()
                if step < 5 {
                    Button("跳过") { next() }.font(AppFont.caption()).foregroundStyle(.secondary)
                }
            }
            .padding(16)
            TabView(selection: $step) {
                intro.tag(0)
                bind.tag(1)
                adopt.tag(2)
                firstCard.tag(3)
                sign.tag(4)
                done.tag(5)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .background(T.paper)
    }

    private func next() { withAnimation { step = min(step + 1, 5) } }

    // MARK: 1 装备须知

    private var intro: some View {
        Flow {
            Text(Copy.onboardingIntroTitle).font(AppFont.caption()).foregroundStyle(T.gold)
            Text("它到了之后,\n你会怎么用").font(AppFont.title(26)).foregroundStyle(T.ink)
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Copy.onboardingIntroItems, id: \.self) { line in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.circle").foregroundStyle(T.mid)
                        Text(line).font(AppFont.body(15)).foregroundStyle(T.ink)
                    }
                }
            }
            .card()
            PrimaryButton(title: "开始") { next() }
            Text(Copy.onboardingSkippable).font(AppFont.caption()).foregroundStyle(.secondary)
        }
    }

    // MARK: 2 绑定(可跳过,先领"虚拟手办"占位)

    private var bind: some View {
        Flow {
            Text("先把你的手办连上").font(AppFont.title(24)).foregroundStyle(T.ink)
            Text("连不上也没关系,可以跳过这一步先去认主").font(AppFont.body(13)).foregroundStyle(.secondary)
            NavigationLink { BindView() } label: {
                MenuRow(icon: "qrcode", title: Copy.bindTitle, note: "扫码 / 输入 SN")
            }
            .card()
            SecondaryButton(title: "先领一只「虚拟手办」看看") { next() }
            Text(Copy.bindFooter).font(AppFont.caption()).foregroundStyle(.secondary)
        }
    }

    // MARK: 3 认主(填名字;第一句自我介绍走 text-turn,普通回合即可,零新增固件)

    private var adopt: some View {
        Flow {
            Text(Copy.onboardingAdoptTitle).font(AppFont.title(24)).foregroundStyle(T.ink)
            Text(Copy.onboardingAdoptIntro).font(AppFont.body(13)).foregroundStyle(.secondary)
            VStack(spacing: 8) {
                BreathingOrb()
                TextField("它的名字", text: $name)
                    .font(.system(size: 24, weight: .semibold, design: .serif))
                    .multilineTextAlignment(.center)
            }
            .card()
            PrimaryButton(title: "就这个") { next() }
            Text("按下去,它会用这个名字叫你。").font(AppFont.caption()).foregroundStyle(.secondary)
        }
    }

    // MARK: 4 第一张角色卡(免费入册;端点 #22 install,失败不阻塞)

    private var firstCard: some View {
        Flow {
            Text(Copy.onboardingCardTitle).font(AppFont.title(24)).foregroundStyle(T.ink)
            Text(Copy.onboardingCardIntro).font(AppFont.body(13)).foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 6) {
                Text("\(name) · 深海书简").font(AppFont.headline()).foregroundStyle(T.ink)
                Text("角色包 · 含连载 6 章").font(AppFont.caption()).foregroundStyle(.secondary)
                TagPill("免费")
            }
            .card()
            PrimaryButton(title: "放进收藏柜") { next() }
        }
    }

    // MARK: 5 契约签署(四条逐字;虚拟仪式,设备无手势)

    private var sign: some View {
        Flow {
            Text(Copy.onboardingSignTitle).font(AppFont.title(22)).foregroundStyle(T.ink)
            Text(Copy.onboardingSignIntro).font(AppFont.body(13)).foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 8) {
                CapLabel(Copy.contractTitle)
                ForEach(Copy.contractItems, id: \.self) { line in
                    Text(line).font(AppFont.body(14)).foregroundStyle(T.ink)
                }
            }
            .card()
            PrimaryButton(title: "签署") {
                signed = true
                UserDefaults.standard.set(true, forKey: "contract.signed.v1")
                next()
            }
            Text("签署在 App 里完成;包装里也有一张实物契约卡。").font(AppFont.caption()).foregroundStyle(.secondary)
        }
    }

    // MARK: 6 完成(开箱第一句话卡,可分享)

    private var done: some View {
        Flow {
            Text("好了,\n它认识你了").font(AppFont.title(26)).foregroundStyle(T.ink)
            VStack(spacing: 8) {
                CapLabel("开箱第一句话卡")
                BreathingOrb()
                Text(Copy.onboardingFirstWords).font(AppFont.headline(17)).foregroundStyle(T.ink)
                Text("—— \(name) · 今天").font(AppFont.caption()).foregroundStyle(.secondary)
            }
            .card()
            ShareLink(item: "\(Copy.onboardingFirstWords) —— \(name) · AI 手办") {
                Label("分享这张卡", systemImage: "square.and.arrow.up")
                    .font(AppFont.headline())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(RoundedRectangle(cornerRadius: 14).fill(T.card))
                    .foregroundStyle(T.mid)
            }
            .buttonStyle(.plain)
            PrimaryButton(title: "开始使用") { env.finishOnboarding() }
        }
    }
}

/// 流程页通用竖排布局
private struct Flow<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) { content }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
