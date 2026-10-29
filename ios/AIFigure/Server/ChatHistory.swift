import Foundation
import CryptoKit

struct LabChatTurn: Codable, Identifiable {
    let id: String
    let position: Int
    let source: String
    let operationId: String?
    let created: Double
    let updated: Double
    let revision: Int
    let userText: String
    let userStatus: String
    let assistantText: String
    let assistantStatus: String
    var userAudioBytes: Int? = nil
    var assistantAudioBytes: Int? = nil
    var assistantNote: String {
        switch assistantStatus {
        case "interrupted": return "已打断"
        case "failed": return "回应未完成"
        case "unknown": return "连接中断，结果未确认"
        case "streaming": return "正在回应…"
        default: return ""
        }
    }
}
struct LabChatPage: Decodable {
    let turns: [LabChatTurn]
    let revision: Int
    let oldest: Int?
    let hasOlder: Bool
    let deviceId: String
    let reset: Bool?
}
struct ChatHistoryCache: Codable {
    var turns: [LabChatTurn] = []
    var revision = 0
    var hasOlder = false
    mutating func merge(_ page: LabChatPage, older: Bool = false) {
        if page.reset == true { turns = []; revision = 0 }
        var byID=Dictionary(uniqueKeysWithValues:turns.map { ($0.id,$0) })
        for row in page.turns where row.revision >= (byID[row.id]?.revision ?? -1) { byID[row.id]=row }
        turns=Array(byID.values).sorted { $0.position < $1.position }
        if older || revision == 0 { hasOlder=page.hasOlder }
        if !older { revision=max(revision,page.revision) }
    }
    static func url(scope: String) throws -> URL {
        let root=try FileManager.default.url(for:.applicationSupportDirectory,in:.userDomainMask,appropriateFor:nil,create:true).appendingPathComponent("ChatHistory",isDirectory:true)
        try FileManager.default.createDirectory(at:root,withIntermediateDirectories:true)
        let name=SHA256.hash(data:Data(scope.utf8)).map { String(format:"%02x",$0) }.joined()
        return root.appendingPathComponent(name+".json")
    }
    static func load(scope: String) throws -> Self {
        let file=try url(scope:scope)
        guard FileManager.default.fileExists(atPath:file.path) else { return Self() }
        let size=try file.resourceValues(forKeys:[.fileSizeKey]).fileSize ?? 0
        guard size <= 20_000_000 else { throw CocoaError(.fileReadCorruptFile) }
        return try JSONDecoder().decode(Self.self,from:Data(contentsOf:file))
    }
    func save(scope: String) throws {
        var bounded=self; bounded.turns=Array(turns.suffix(2000));if turns.count>2000 { bounded.hasOlder=true }
        let bytes=try JSONEncoder().encode(bounded)
        #if os(iOS)
        try bytes.write(to:Self.url(scope:scope),options:[.atomic,.completeFileProtectionUntilFirstUserAuthentication])
        #else
        try bytes.write(to:Self.url(scope:scope),options:.atomic)
        #endif
    }
}
