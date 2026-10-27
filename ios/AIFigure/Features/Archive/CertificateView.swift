import SwiftUI

/// 出生证 + 契约卡(archive/certificate):虚拟物料主展位(`17` §3.1 虚拟化改造)。
/// 契约四条与原型逐字一致;可存图/分享走系统分享面板(ShareLink)。
struct CertificateView: View {
    let character: FigureCharacter

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                birthCard
                contractCard
                recordsCard
                Text("这张出生证与契约卡,包装里也各有一张实物;上面的编号与底座金属铭牌一致。")
                    .font(AppFont.caption()).foregroundStyle(.secondary)
            }
            .padding(16)
        }
        .background(T.paper)
        .navigationTitle("出生证与契约")
    }

    // 出生证:名字栏手写、编号、日期、脚注
    private var birthCard: some View {
        VStack(spacing: 10) {
            Text("角 色 出 生 证")
                .font(.system(size: 15, weight: .semibold, design: .serif))
                .foregroundStyle(T.gold)
                .tracking(4)
            Image(systemName: "water.waves").font(.system(size: 26)).foregroundStyle(T.mid)
            Text(character.displayName)
                .font(.system(size: 26, weight: .semibold, design: .serif))
                .multilineTextAlignment(.center)
                .foregroundStyle(T.ink)
            Divider()
            HStack {
                LabeledRow(title: "编号 \(character.number ?? "待颁发")")
                LabeledRow(title: character.packVersion.map { "角色包 v\($0)" } ?? "角色包")
            }
            ShareLink(item: shareText) {
                Label("分享文字", systemImage: "square.and.arrow.up")
                    .font(AppFont.caption()).foregroundStyle(T.mid)
            }
        }
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(hex: 0xFFFDF6)))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(T.gold.opacity(0.5), lineWidth: 1))
        .padding(.vertical, 4)
    }

    private var shareText: String {
        """
        「\(character.displayName)」的出生证
        编号 \(character.number ?? "待颁发") · \(character.adoptedAt ?? "")
        —— AI 手办
        """
    }

    /// 契约卡:四条逐字 + 签署
    private var contractCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            CapLabel(Copy.contractTitle)
            ForEach(Copy.contractItems, id: \.self) { line in
                Text(line).font(AppFont.body(14)).foregroundStyle(T.ink)
            }
            Text("签署暂未开放").font(AppFont.body(13)).foregroundStyle(.secondary)

        }
        .card()
    }

    private var recordsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            CapLabel("签署记录")
            LabeledRow(title: "暂无签署记录", note: "")

        }
        .card()
    }
}
