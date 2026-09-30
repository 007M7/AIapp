import SwiftUI

// 设计令牌 —— 与 AIapp prototype/src/core.mjs 的 T 一一对应,三端(小程序/App/Web)同一套视觉。

enum T {
    static let navy = Color(hex: 0x26325F)
    static let mid = Color(hex: 0x3E63B0)
    static let ice = Color(hex: 0xA8D8F0)
    static let blue = Color(hex: 0x7EC4E8)
    static let gold = Color(hex: 0xC9A227)
    static let paper = Color(hex: 0xFBF8F1)
    static let card = Color(hex: 0xEDF3FF)
    static let ink = Color(hex: 0x1B2440)
}

extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xff) / 255,
                  green: Double((hex >> 8) & 0xff) / 255,
                  blue: Double(hex & 0xff) / 255)
    }
}

// 字体:标题用 rounded(圆体感),正文系统体
enum AppFont {
    static func title(_ size: CGFloat = 22) -> Font { .system(size: size, weight: .bold, design: .rounded) }
    static func headline(_ size: CGFloat = 17) -> Font { .system(size: size, weight: .semibold, design: .rounded) }
    static func body(_ size: CGFloat = 15) -> Font { .system(size: size) }
    static func caption(_ size: CGFloat = 12) -> Font { .system(size: size) }
}

// MARK: - 通用组件

/// 卡片底
struct CardBackground: ViewModifier {
    var color: Color = T.card
    func body(content: Content) -> some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 16).fill(color))
    }
}

extension View {
    func card(_ color: Color = T.card) -> some View { modifier(CardBackground(color: color)) }
}

/// 分区小标题(原型里的 cap)
struct CapLabel: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(T.mid.opacity(0.9))
            .textCase(.uppercase)
            .padding(.top, 6)
    }
}

/// 胶囊(状态/入口),禁红点与数字气泡(PRD §4.3:首页禁数值化显示)
struct TagPill: View {
    let text: String
    var tint: Color = T.mid
    var body: some View {
        Text(text)
            .font(AppFont.caption(12))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(tint.opacity(0.12)))
    }
}

/// LED 呼吸镜像(手办状态卡的"它在桌上"),呼吸动效,不是任何计量显示
struct BreathingOrb: View {
    var lit: Bool = true
    @State private var on = false
    var body: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [T.mid.opacity(0.22), T.mid.opacity(0.08), .clear],
                                     center: .center, startRadius: 8, endRadius: 56))
                .frame(width: 112, height: 112)
            Circle()
                .fill(RadialGradient(colors: [Color(hex: 0xBFD4F2), T.mid],
                                     center: UnitPoint(x: 0.35, y: 0.32), startRadius: 2, endRadius: 22))
                .frame(width: 36, height: 36)
                .opacity(lit ? 1 : 0.35)
                .shadow(color: T.mid.opacity(on ? 0.55 : 0.2), radius: on ? 18 : 8)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) { on = true }
        }
    }
}

/// 主按钮
struct PrimaryButton: View {
    let title: String
    var icon: String? = nil
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon { Image(systemName: icon) }
                Text(title).font(AppFont.headline())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: 14).fill(T.mid))
            .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
    }
}

/// 次按钮(描边)
struct SecondaryButton: View {
    let title: String
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppFont.headline())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(RoundedRectangle(cornerRadius: 14).stroke(T.mid.opacity(0.5), lineWidth: 1))
                .foregroundStyle(T.mid)
        }
        .buttonStyle(.plain)
    }
}

/// 列表行(菜单/说明两用):左标题右注
struct MenuRow: View {
    let icon: String
    let title: String
    var note: String = ""
    var tint: Color = T.ink
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundStyle(T.mid).frame(width: 22)
            Text(title).font(AppFont.body()).foregroundStyle(tint)
            Spacer()
            if !note.isEmpty {
                Text(note).font(AppFont.caption()).foregroundStyle(.secondary)
            }
            Image(systemName: "chevron.right").font(AppFont.caption()).foregroundStyle(.tertiary)
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

/// 空态卡(引导语,全大写禁用词检查已过)
struct EmptyStateCard: View {
    let title: String
    let note: String
    var body: some View {
        VStack(spacing: 8) {
            Text(title).font(AppFont.headline()).foregroundStyle(T.ink)
            Text(note).font(AppFont.body(13)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .card()
    }
}

/// 页面外壳:标题 + 副文案
struct PageHeader: View {
    let title: String
    var subtitle: String = ""
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(AppFont.title(24)).foregroundStyle(T.ink)
            if !subtitle.isEmpty {
                Text(subtitle).font(AppFont.body(13)).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
