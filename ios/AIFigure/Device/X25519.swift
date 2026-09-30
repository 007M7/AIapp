import Foundation
import CryptoKit

/// X25519(CryptoKit,系统随机源)。
/// Security 1 无 PoP:AES 密钥就是 X25519 共享密钥本身,初始计数器 = device_random
/// (小程序 utils/prov.js 的 handshake 同款,无任何 KDF)。
enum X25519 {
    struct KeyPair {
        let privateKey: Curve25519.KeyAgreement.PrivateKey
        /// 32 字节公钥
        var publicKeyData: Data { privateKey.publicKey.rawRepresentation }
    }

    static func generate() -> KeyPair { KeyPair(privateKey: Curve25519.KeyAgreement.PrivateKey()) }

    /// 32 字节共享密钥
    static func sharedSecret(priv: KeyPair, peerPublic: Data) throws -> Data {
        guard peerPublic.count == 32 else { throw ProvError.crypto("设备公钥必须是 32 字节") }
        let peer = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: peerPublic)
        let ss = try priv.privateKey.sharedSecretFromKeyAgreement(with: peer)
        return ss.withUnsafeBytes { Data($0) }
    }
}
