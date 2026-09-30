import SwiftUI

/// 出生证 + 契约卡(archive/certificate):虚拟物料主展位(`17` §3.1 虚拟化改造)。
/// 契约四条与原型逐字一致;可存图/分享走系统分享面板(ShareLink)。
struct CertificateView: View {
    let character: FigureCharacter
    @State private var nameInput = ""
    @State private var signed = UserDefaults.standard.bool(forKey: "contract.signed.v1")

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
        .onAppear { nameInput = character.displayName }
    }

    // 出生证:名字栏手写、编号、日期、脚注
    private var birthCard: some View {
        VStack(spacing: 10) {
            Text("角 色 出 生 证")
                .font(.system(size: 15, weight: .semibold, design: .serif))
                .foregroundStyle(T.gold)
                .tracking(4)
            Image(systemName: "water.waves").font(.system(size: 26)).foregroundStyle(T.mid)
            TextField("名字由你写下", text: $nameInput)
                .font(.system(size: 26, weight: .semibold, design: .serif))
                .multilineTextAlignment(.center)
                .foregroundStyle(T.ink)
            Text("名字由你写下,随时可以改;每次更改都会留下记录")
                .font(AppFont.caption()).foregroundStyle(.secondary)
            Divider()
            HStack {
                LabeledRow(title: "编号 \(character.number ?? "待颁发")")
                LabeledRow(title: character.packVersion.map { "角色包 v\($0)" } ?? "角色包")
            }
            ShareLink(item: shareText) {
                Label("存图 / 分享", systemImage: "square.and.arrow.up")
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
        「\(nameInput)」的出生证
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
            PrimaryButton(title: signed ? "已签署 · 查看记录" : "签署") { signed = true }
            Text(Copy.contractSignNote).font(AppFont.caption()).foregroundStyle(.secondary)
        }
        .card()
        .onChange(of: signed) { _, value in
            if value { UserDefaults.standard.set(true, forKey: "contract.signed.v1") }
        }
    }

    private var recordsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            CapLabel("签署记录")
            LabeledRow(title: signed ? "首次签署 · 契约 v1" : "还没有签署", note: character.adoptedAt ?? "")
            Text(Copy.contractSignNote).font(AppFont.caption()).foregroundStyle(.secondary)
        }
        .card()
    }
}
