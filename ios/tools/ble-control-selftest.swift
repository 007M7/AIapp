import Foundation

actor BLEPeer {
    let pair = X25519.generate()
    var client = Data()
    var stream: AesCtr?
    var failNext = false
    var controls = 0
    func failTransport() { failNext = true }
    func count() -> Int { controls }
    func transfer(_ ep: String, _ bytes: Data) throws -> Data {
        if ep == "prov-session" {
            let outer = try MiniPB.decode(bytes)
            let security = try MiniPB.decode(outer[11]!.bytesValue!)
            if let start = security[20]?.bytesValue {
                client = try MiniPB.decode(start)[1]!.bytesValue!
                let iv = Data(repeating: 7, count: 16)
                stream = try AesCtr(key: X25519.sharedSecret(priv: pair, peerPublic: client), iv: iv)
                return MiniPB.encode([PBField(2,.varint(1)), PBField(11,.message([
                    PBField(21,.message([PBField(2,.bytes(pair.publicKeyData)), PBField(3,.bytes(iv))]))]))])
            }
            let verify = try MiniPB.decode(security[22]!.bytesValue!)[2]!.bytesValue!
            assert(stream!.update(verify) == pair.publicKeyData)
            return MiniPB.encode([PBField(2,.varint(1)), PBField(11,.message([
                PBField(23,.message([PBField(3,.bytes(stream!.update(client)))]))]))])
        }
        assert(ep == "device-control")
        controls += 1
        if failNext { throw ProvError.ble("simulated transport failure") }
        let decoded = stream!.update(bytes)
        let value = try JSONSerialization.jsonObject(with: decoded) as! [String:Any]
        assert(value["o"] as? String == "status")
        return stream!.update(Data("{\"v\":1,\"result\":\"completed\"}".utf8))
    }
}

@main struct BLEControlSelftest {
    static func main() async throws {
        let key = String(repeating: "a", count: 64)
        let id = String(repeating: "b", count: 32)
        let request = try BLEControlProtocol.request(op: "wifi", key: key, id: id,
            fields: ["s":String(repeating:"鲸",count:10),"p":String(repeating:"x",count:63)])
        assert(request.count <= 384)
        for bad in ["",String(repeating:"g",count:64)] {
            do { _ = try BLEControlProtocol.request(op:"status",key:bad); fatalError("accepted invalid key") } catch is ProvError {}
        }
        do { _ = try BLEControlProtocol.request(op:"status",key:key,fields:["k":"override"]); fatalError("reserved field overwritten") } catch is ProvError {}
        for bad in ["{}","{\"v\":2,\"result\":\"completed\"}","{\"v\":1,\"result\":\"success\"}"] {
            do { _ = try BLEControlProtocol.reply(Data(bad.utf8)); fatalError("accepted invalid reply") } catch is ProvError {}
        }
        let base: [String:Any] = ["wifi":false,"ready":false,"usb":true,"volume":75,"ssid":"","ip":"0.0.0.0","state":"ERR","firmware":"test","host":"192.168.1.2","port":8766,"switching":false]
        var fixture = base
        func status() throws -> BLEDeviceStatus { try JSONDecoder().decode(BLEDeviceStatus.self,from:JSONSerialization.data(withJSONObject:fixture)) }
        let offline = try status(); assert(offline.label == "蓝牙已连接 · 离线可用")
        fixture["wifi"]=true
        let wifiOnly = try status(); assert(wifiOnly.label == "已联网 · 互动服务未连接")
        fixture["ready"]=true; fixture["state"]="PLAY"
        let playing = try status(); assert(playing.label == "正在回应")
        let peer = BLEPeer()
        let session = ProvisionSession { ep,data in try await peer.transfer(ep,data) }
        try await session.handshake()
        for _ in 0..<3 {
            let data = try await session.control(BLEControlProtocol.request(op:"status",key:key))
            let reply = try BLEControlProtocol.reply(data); assert(reply["result"] as? String == "completed")
        }
        await peer.failTransport()
        do { _ = try await session.control(request); fatalError("transport failure ignored") } catch is ProvError {}
        let count = await peer.count()
        do { _ = try await session.control(request); fatalError("broken session reused") } catch is ProvError {}
        let after = await peer.count(); assert(count == after)
        print("BLE control protocol, state separation, encrypted stream continuity and transport failure tests passed")
    }
}
