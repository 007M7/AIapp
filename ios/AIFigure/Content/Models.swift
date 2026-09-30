import Foundation

// MARK: - /api/v1 数据模型
//
// 字段口径对齐 `14` §5.3 表骨架;服务端 M1 前部分字段可能缺省,全部做成 Optional,
// 界面按"缺省就不显示"处理。新增字段先对表,不猜。

struct MeInfo: Codable {
    var id: String?
    var nickname: String?
    var avatarUrl: String?
}

struct DeviceItem: Codable, Identifiable {
    var id: String
    var sn: String?
    var name: String?
    var online: Bool?
    var fw: String?
    var battery: Int?
    var characterId: String?
    var characterName: String?

    var displayName: String { name ?? sn.map { "手办 \($0)" } ?? "我的手办" }
}

struct FigureCharacter: Codable, Identifiable {
    var id: String
    var name: String?
    var packTitle: String?
    var packVersion: String?
    var number: String?           // 出生证编号,与底座金属铭牌一致(Q-52)
    var adoptedAt: String?
    var voiceName: String?
    var bibleTags: [String]?      // 性格/口癖/关系线,叙事化标签(禁数值化,14 红线#3)
    var facts: [String]?          // 它记得的相处事实(展示级)
    var deviceName: String?
    var active: Bool?

    var displayName: String { name ?? "未命名角色" }
}

struct MemoryItem: Codable, Identifiable {
    var id: String
    var factText: String?
    var category: String?         // fact / milestone / preference …(14 §5.3 memory_facts)
    var confidence: Double?
    var status: String?           // active / archived(封存)/ hidden
    var pinned: Bool?
    var sourceTurnId: String?
    var createdAt: String?

    var isArchived: Bool { status == "archived" || status == "hidden" }
}

struct TurnItem: Codable, Identifiable {
    var id: String
    var role: String?             // user / assistant
    var text: String?
    var createdAt: String?
}

struct PackItem: Codable, Identifiable {
    var id: String
    var title: String?
    var category: String?         // character / skin / voice / event / goods(五架,12 §2.2)
    var author: String?
    var official: Bool?
    var priceCents: Int?
    var free: Bool?
    var summary: String?
    var episodes: Int?
    var previewUrl: String?

    var priceText: String {
        if free == true || priceCents == nil || priceCents == 0 { return "免费" }
        return String(format: "¥ %.0f", Double(priceCents!) / 100)
    }
}

struct CommunityPost: Codable, Identifiable {
    var id: String
    var title: String?
    var summary: String?
    var authorName: String?
    var official: Bool?
    var packId: String?
    var likeCount: Int?
}

struct AuditionResult: Codable {
    var audioUrl: String?
    var audioBase64: String?
}

struct TextTurnResult: Codable {
    var text: String?
    var audioUrl: String?
    var audioBase64: String?
}
