import SwiftUI

/// 首次开箱仪式(`19` §6.1,六步):装备须知 → 绑定 → 认主 → 第一张角色卡 → 契约签署 → 完成。
/// 本地介绍草稿可恢复；不代表服务端认主、角色入册或正式签署。
struct OnboardingFlow: View {
    @EnvironmentObject private var env: AppEnv
    @State private var draft = OnboardingDraft.read()

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("第 \(draft.step + 1) 步,共 6 步").font(AppFont.caption()).foregroundStyle(.secondary)
                Spacer()
                Button("稍后继续") { env.showOnboarding = false }
                    .font(AppFont.caption())
                if draft.step < 5 {
                    Button("跳过") { next() }.font(AppFont.caption()).foregroundStyle(.secondary)
                }
            }
            .padding(16)
            TabView(selection: $draft.step) {
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
        .onChange(of: draft) { value in value.save() }
    }

    private func next() { withAnimation { draft.step = min(draft.step + 1, 5) } }

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

        }
    }

    // MARK: 2 绑定(可跳过,先领"虚拟手办"占位)

    private var bind: some View {
        Flow {
            Text("先把你的手办连上").font(AppFont.title(24)).foregroundStyle(T.ink)
            Text("也可以稍后绑定，先看看开箱介绍。").font(AppFont.body(13)).foregroundStyle(.secondary)
            NavigationLink { BindView() } label: {
                MenuRow(icon: "qrcode", title: Copy.bindTitle, note: "输入序列号 · 连接 Wi-Fi")
            }
            .card()
            SecondaryButton(title: "稍后绑定 · 继续了解") { next() }
        }
    }

    // MARK: 3 名字草稿（服务端认主未接入）

    private var adopt: some View {
        Flow {
            Text(Copy.onboardingAdoptTitle).font(AppFont.title(24)).foregroundStyle(T.ink)
            Text("名字草稿").font(AppFont.body(13)).foregroundStyle(.secondary)
            VStack(spacing: 8) {
                BreathingOrb()
                TextField("它的名字", text: $draft.name)
                    .font(.system(size: 24, weight: .semibold, design: .serif))
                    .multilineTextAlignment(.center)
            }
            .card()
            PrimaryButton(title: "就这个") { next() }
            Text("仅保存到本机").font(AppFont.caption()).foregroundStyle(.secondary)
        }
    }

    // MARK: 4 第一张角色卡预览（不授予权益）

    private var firstCard: some View {
        Flow {
            Text(Copy.onboardingCardTitle).font(AppFont.title(24)).foregroundStyle(T.ink)
            Text("角色卡预览").font(AppFont.body(13)).foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 6) {
                Text("\(draft.name) · 深海书简").font(AppFont.headline()).foregroundStyle(T.ink)
                Text("未入册").font(AppFont.caption()).foregroundStyle(.secondary)
                TagPill("预览")
            }
            .card()
            PrimaryButton(title: "看下一步") { next() }
        }
    }

    // MARK: 5 阅读契约（不是正式签署）

    private var sign: some View {
        Flow {
            Text("读一读这份契约").font(AppFont.title(22)).foregroundStyle(T.ink)
            VStack(alignment: .leading, spacing: 8) {
                CapLabel(Copy.contractTitle)
                ForEach(Copy.contractItems, id: \.self) { line in
                    Text(line).font(AppFont.body(14)).foregroundStyle(T.ink)
                }
            }
            .card()
            PrimaryButton(title: "我已读过 · 继续") {
                draft.contractRead = true
                next()
            }
            Text("正式签署暂未开放").font(AppFont.caption()).foregroundStyle(.secondary)
        }
    }

    // MARK: 6 完成(开箱第一句话卡,可分享)

    private var done: some View {
        Flow {
            Text("介绍完成").font(AppFont.title(26)).foregroundStyle(T.ink)
            VStack(spacing: 8) {
                CapLabel("角色台词预览")
                BreathingOrb()
                Text(Copy.onboardingFirstWords).font(AppFont.headline(17)).foregroundStyle(T.ink)
                Text("—— \(draft.name) · 今天").font(AppFont.caption()).foregroundStyle(.secondary)
            }
            .card()
            ShareLink(item: "\(Copy.onboardingFirstWords) —— \(draft.name) · AI 手办") {
                Label("分享这句预览文字", systemImage: "square.and.arrow.up")
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
