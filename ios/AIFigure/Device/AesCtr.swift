import Foundation

// AES-256-CTR,只做加密方向(CTR 模式解密 = 加密)。
//
// 是小程序 lib/aes_ctr.js 的 1:1 Swift 移植:按 FIPS-197 直写的字节版,S 盒现算,
// 密钥流字节偏移跨调用保留(不按块对齐),计数器 128 bit 大端整体 +1 —— 与
// mbedtls_aes_crypt_ctr 的 nc_off / stream_block 行为一致。配网全程只加解密几百字节,
// 快慢无所谓,可读、可对着标准逐步核对更重要;正确性由 ios/tools/selftest.swift
// 的 NIST 向量与 JS 实现交叉兜底。

enum AES256 {
    // S 盒现算:用生成元 3 遍历 GF(2^8) 的非零元素,同时得到逆元,再做仿射变换
    static let sbox: [UInt8] = {
        var s = [UInt8](repeating: 0, count: 256)
        func rotl(_ x: UInt8, _ n: UInt8) -> UInt8 { (x << n) | (x >> (8 - n)) }
        var p: UInt8 = 1, q: UInt8 = 1
        repeat {
            p = p ^ (p << 1) ^ (p & 0x80 != 0 ? 0x1b : 0)       // p *= 3
            q ^= q << 1; q ^= q << 2; q ^= q << 4               // q /= 3
            if q & 0x80 != 0 { q ^= 0x09 }
            s[Int(p)] = q ^ rotl(q, 1) ^ rotl(q, 2) ^ rotl(q, 3) ^ rotl(q, 4) ^ 0x63
        } while p != 1
        s[0] = 0x63
        return s
    }()

    static func xtime(_ a: UInt8) -> UInt8 { (a << 1) ^ (a & 0x80 != 0 ? 0x1b : 0) }

    // 32 字节密钥 → 15 轮 × 16 字节轮密钥(240 字节)
    static func expandKey(_ key: [UInt8]) -> [UInt8] {
        precondition(key.count == 32, "AES-256 需要 32 字节密钥")
        var w = [UInt8](repeating: 0, count: 240)
        w.replaceSubrange(0 ..< 32, with: key)
        var rcon: UInt8 = 1
        var i = 32
        while i < 240 {
            var t0 = w[i - 4], t1 = w[i - 3], t2 = w[i - 2], t3 = w[i - 1]
            if i % 32 == 0 {                                     // RotWord + SubWord + Rcon
                let t = t0
                t0 = sbox[Int(t1)] ^ rcon; t1 = sbox[Int(t2)]; t2 = sbox[Int(t3)]; t3 = sbox[Int(t)]
                rcon = xtime(rcon)
            } else if i % 32 == 16 {                             // AES-256 特有:中间多一次 SubWord
                t0 = sbox[Int(t0)]; t1 = sbox[Int(t1)]; t2 = sbox[Int(t2)]; t3 = sbox[Int(t3)]
            }
            w[i] = w[i - 32] ^ t0
            w[i + 1] = w[i - 31] ^ t1
            w[i + 2] = w[i - 30] ^ t2
            w[i + 3] = w[i - 29] ^ t3
            i += 4
        }
        return w
    }

    // 加密一个块。state 按列存:s[列*4 + 行]
    static func encryptBlock(_ rk: [UInt8], _ input: [UInt8]) -> [UInt8] {
        var s = [UInt8](repeating: 0, count: 16)
        for i in 0 ..< 16 { s[i] = input[i] ^ rk[i] }
        for round in 1 ... 14 {
            var t = [UInt8](repeating: 0, count: 16)
            for c in 0 ..< 4 {                                   // SubBytes + ShiftRows(第 r 行左移 r)
                for r in 0 ..< 4 { t[c * 4 + r] = sbox[Int(s[((c + r) & 3) * 4 + r])] }
            }
            if round < 14 {                                      // MixColumns,最后一轮没有
                for c in 0 ..< 4 {
                    let a0 = t[c * 4], a1 = t[c * 4 + 1], a2 = t[c * 4 + 2], a3 = t[c * 4 + 3]
                    let x = a0 ^ a1 ^ a2 ^ a3
                    t[c * 4] = a0 ^ x ^ xtime(a0 ^ a1)
                    t[c * 4 + 1] = a1 ^ x ^ xtime(a1 ^ a2)
                    t[c * 4 + 2] = a2 ^ x ^ xtime(a2 ^ a3)
                    t[c * 4 + 3] = a3 ^ x ^ xtime(a3 ^ a0)
                }
            }
            for i in 0 ..< 16 { t[i] ^= rk[round * 16 + i] }
            s = t
        }
        return s
    }
}

/// 连续的 CTR 密钥流。protocomm Security 1 里整个会话只有这一条,两个方向、
/// 所有端点共用,按调用顺序消耗(prov.js 同款语义)—— 请求绝不能交叠,
/// 传输一旦出错只能断开重来(密钥流位置两端可能已错开)。
final class AesCtr {
    private let rk: [UInt8]
    private var counter: [UInt8]
    private var block = [UInt8](repeating: 0, count: 16)
    private var off = 16

    init(key: Data, iv: Data) throws {
        guard key.count == 32 else { throw ProvError.crypto("AES-256 需要 32 字节密钥") }
        guard iv.count == 16 else { throw ProvError.crypto("CTR 初始计数器必须 16 字节") }
        rk = AES256.expandKey([UInt8](key))
        counter = [UInt8](iv)
    }

    func update(_ data: Data) -> Data {
        let input = [UInt8](data)
        var out = [UInt8](repeating: 0, count: input.count)
        for k in 0 ..< input.count {
            if off == 16 {
                block = AES256.encryptBlock(rk, counter)
                var j = 15
                while j >= 0 { counter[j] &+= 1; if counter[j] != 0 { break }; j -= 1 }  // 回绕成 0 才进位
                off = 0
            }
            out[k] = input[k] ^ block[off]
            off += 1
        }
        return Data(out)
    }
}
