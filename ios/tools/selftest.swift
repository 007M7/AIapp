// iOS 移植层自测:MiniPB(protobuf)与 AesCtr(AES-256-CTR)对照小程序 JS 实现的向量。
//
// 向量来源(2026-09-29 用 miniprogram/utils/pb.js + lib/aes_ctr.js + lib/x25519.js 实跑生成):
//   - NIST SP 800-38A F.5.5 AES-256-CTR 官方向量
//   - 非对齐分片连续性(5/7/13/22 字节四段,跨调用密钥流偏移)
//   - 随机 37 字节对拍向量(RAND*)
//   - X25519 RFC 7748 §5.2 测试向量(仅 CryptoKit 平台跑)
//   - 握手报文形状:Cmd0(SessionData+sc0)与 Resp0(sr0)的真实字节
//
// 用法(Mac 上,工程根目录执行):
//   swift ios/tools/selftest.swift \
//         ios/AIFigure/Device/MiniPB.swift \
//         ios/AIFigure/Device/AesCtr.swift \
//         ios/AIFigure/Device/X25519.swift
// 退出码 0 = 全过;任何断言失败立即中止并打印 got/want。

import Foundation

var passed = 0
func ok(_ name: String) { passed += 1; print("  ✔ \(name)") }
func fail(_ name: String, _ detail: String) {
    print("  ✘ \(name): \(detail)")
    exit(1)
}
func hex(_ d: Data) -> String { d.map { String(format: "%02x", $0) }.joined() }
func data(_ s: String) -> Data {
    var out = Data()
    var i = s.startIndex
    while i < s.endIndex {
        let next = s.index(i, offsetBy: 2)
        out.append(UInt8(s[i..<next], radix: 16)!)
        i = next
    }
    return out
}
func expectHex(_ name: String, _ got: Data, _ want: String) {
    let g = hex(got)
    if g == want { ok(name) } else { fail(name, "got \(g) want \(want)") }
}

print("MiniPB")
expectHex("varint 150", MiniPB.encode([PBField(1, .varint(150))]), "089601")
expectHex("嵌套消息", MiniPB.encode([PBField(2, .message([PBField(1, .bytes(MiniPB.utf8("hi")))]))]), "12040a026869")
expectHex("零值不上线", MiniPB.encode([PBField(1, .varint(0)), PBField(2, .varint(3))]), "1003")

// Cmd0:SessionData{sec_ver=1, sec1{sc0{client_pubkey=AB*32}}}
let cliPub = Data(repeating: 0xab, count: 32)
expectHex("握手 Cmd0 报文", MiniPB.encode([
    PBField(2, .varint(1)),
    PBField(11, .message([PBField(20, .message([PBField(1, .bytes(cliPub))]))])),
]), "10015a25a201220a20" + String(repeating: "ab", count: 32))

// Resp0 解码:SessionData{sec_ver=1, sec1{sr0{status=0, dev_pubkey=01..20, dev_random=(i*3)&ff}}}
do {
    let wire = data("10015a37aa013412200102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f201a10000306090c0f1215181b1e2124272a2d")
    let d = try MiniPB.decode(wire)
    guard d[2]?.varintValue == 1 else { fail("Resp0 sec_ver", "字段 2 不是 1") }
    let sec1 = try MiniPB.decode(d[11]?.bytesValue ?? Data())
    let sr0 = try MiniPB.decode(sec1[21]?.bytesValue ?? Data())
    let devPub = sr0[2]?.bytesValue ?? Data()
    let devRand = sr0[3]?.bytesValue ?? Data()
    if devPub == Data((1...32).map { UInt8($0) }) { ok("Resp0 dev_pubkey 32B") } else { fail("Resp0 dev_pubkey", hex(devPub)) }
    if devRand.count == 16 { ok("Resp0 dev_random 16B") } else { fail("Resp0 dev_random", "长度 \(devRand.count)") }
} catch { fail("Resp0 解码", "\(error)") }

print("AesCtr(NIST SP 800-38A F.5.5)")
do {
    let key = data("603deb1015ca71be2b73aef0857d77811f352c073b6108d72d9810a30914dff4")
    let iv = data("f0f1f2f3f4f5f6f7f8f9fafbfcfdfeff")
    let pt = data("6bc1bee22e409f96e93d7e117393172aae2d8a571e03ac9c9eb76fac45af8e5130c81c46a35ce411")

    let c1 = try AesCtr(key: key, iv: iv)
    expectHex("块 1", c1.update(pt[0..<16]), "601ec313775789a5b7a7f504bbf3d228")
    expectHex("块 2", c1.update(pt[16..<32]), "f443e3ca4d62b59aca84e990cacaf5c5")
    expectHex("尾部 8B(非对齐)", c1.update(pt[32..<40]), "2b0930daa23de94c")

    // 非对齐分片连续性:5/7/13/15 字节四段,密钥流偏移跨调用保留
    let c2 = try AesCtr(key: key, iv: iv)
    var chunked = Data()
    for r in [0..<5, 5..<12, 12..<25, 25..<40] { chunked.append(c2.update(pt[r])) }
    expectHex("分片连续 = 整段",
              chunked,
              "601ec313775789a5b7a7f504bbf3d228f443e3ca4d62b59aca84e990cacaf5c52b0930daa23de94c")

    // JS 实现随机对拍向量
    let rk = data("01080f161d242b323940474e555c636a71787f868d949ba2a9b0b7bec5ccd3da")
    let ri = data("030e19242f3a45505b66717c87929da8")
    let rp = data("05121f2c394653606d7a8794a1aebbc8d5e2effc091623303d4a5764717e8b98a5b2bfccd9")
    let c3 = try AesCtr(key: rk, iv: ri)
    expectHex("RAND 37B 对拍", c3.update(rp), "675561eeeb61c3f99dd7a0b2792d1fddd757fa2250d7ba3d5eb02566d39f08ffa072136994")
} catch { fail("AesCtr 初始化", "\(error)") }

#if canImport(CryptoKit)
print("X25519(RFC 7748 §5.2)")
do {
    let alicePriv = data("77076d0a7318a57d3c16c17251b26645df4c2f87ebc0992ab177fba51db92c2a")
    let bobPub = data("de9edb7d7b7dc1b4d35b61c2ece435373f8343c85b78674dadfc7e146f882b4f")
    let kp = try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: alicePriv)
    expectHex("alice 公钥", kp.publicKey.rawRepresentation,
              "8520f0098930a754748b7ddcb43ef75a0dbf3a0d26381af4eba4a98eaa9b4e6a")
    let peer = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: bobPub)
    let ss = try kp.sharedSecretFromKeyAgreement(with: peer)
    expectHex("共享密钥", ss.withUnsafeBytes { Data($0) },
              "4a5d9d5ba4ce2de1728e3bf480350f25e07e21c947d19e3376f09b3c1e161742")
} catch { fail("X25519", "\(error)") }
#endif

print("\n全部 \(passed) 项通过")
exit(0)
