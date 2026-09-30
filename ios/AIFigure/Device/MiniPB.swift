import Foundation

// 最小 protobuf 编解码 —— 配网只用到 varint(0) 与 length-delimited(2) 两种线型。
// 与小程序 miniprogram/utils/pb.js 逐条对齐:
//   编码:varint 等于 0 不写(proto3 默认值不上线);嵌套消息**总是写** —— oneof 成员靠"在场"表达
//   解码:返回 [字段号: PBValue];缺的字段就是 nil,调用方按 proto3 当 0

enum PBValue {
    case varint(UInt64)
    case bytes(Data)
    case message([PBField])

    var varintValue: UInt64? { if case .varint(let v) = self { return v }; return nil }
    var bytesValue: Data? { if case .bytes(let d) = self { return d }; return nil }
    var messageValue: [PBField]? { if case .message(let f) = self { return f }; return nil }
}

struct PBField {
    let number: UInt32
    let value: PBValue
    init(_ number: UInt32, _ value: PBValue) { self.number = number; self.value = value }
}

enum MiniPB {
    // ---- 编码 ----
    static func encode(_ fields: [PBField]) -> Data {
        var out = Data()
        for f in fields {
            switch f.value {
            case .varint(let v):
                if v == 0 { continue }
                putVarint(&out, UInt64(f.number) << 3)          // wire type 0
                putVarint(&out, v)
            case .bytes(let b):
                putVarint(&out, UInt64(f.number) << 3 | 2)      // wire type 2
                putVarint(&out, UInt64(b.count))
                out.append(b)
            case .message(let m):
                let body = encode(m)
                putVarint(&out, UInt64(f.number) << 3 | 2)
                putVarint(&out, UInt64(body.count))
                out.append(body)
            }
        }
        return out
    }

    // ---- 解码 ----
    static func decode(_ data: Data) throws -> [UInt32: PBValue] {
        var msg: [UInt32: PBValue] = [:]
        let a = [UInt8](data)
        var i = 0
        func varint() throws -> UInt64 {
            var n: UInt64 = 0, shift: UInt64 = 0
            while true {
                guard i < a.count else { throw ProvError.proto("protobuf 截断") }
                let b = a[i]; i += 1
                n |= UInt64(b & 0x7f) << shift
                if b & 0x80 == 0 { return n }
                shift += 7
                if shift > 63 { throw ProvError.proto("protobuf varint 过长") }
            }
        }
        while i < a.count {
            let tag = try varint()
            let no = UInt32(tag >> 3)
            switch tag & 7 {
            case 0: msg[no] = .varint(try varint())
            case 2:
                let len = Int(try varint())
                guard i + len <= a.count else { throw ProvError.proto("protobuf 截断") }
                msg[no] = .bytes(Data(a[i ..< i + len]))
                i += len
            case 1: i += 8                                  // 用不到的定长类型,跳过
            case 5: i += 4
            default: throw ProvError.proto("protobuf 线型不支持: \(tag & 7)")
            }
        }
        return msg
    }

    // SSID 可能有中文,走完整 UTF-8;设备回来的字符串(proto-ver 的 JSON、IP)按 UTF-8 解
    static func utf8(_ s: String) -> Data { Data(s.utf8) }
    static func ascii(_ d: Data) -> String { String(decoding: d, as: UTF8.self) }

    private static func putVarint(_ out: inout Data, _ n: UInt64) {
        var v = n
        while v > 0x7f { out.append(UInt8(v & 0x7f) | 0x80); v >>= 7 }
        out.append(UInt8(v))
    }
}

// 配网全链路的错误:文案直接面向用户(与小程序 ble.js 的 errText 同一风格)。
enum ProvError: LocalizedError {
    case proto(String)      // 编解码
    case crypto(String)     // 密钥/计数器
    case ble(String)        // 蓝牙传输层
    case session(String)    // Security 1 会话/握手
    case status(String)     // 设备拒绝(非 0 status)

    var errorDescription: String? {
        switch self {
        case .proto(let m), .crypto(let m), .ble(let m), .session(let m), .status(let m):
            return m
        }
    }
}
