import Foundation

/// 乐鑫 protocomm / network_provisioning 客户端,Security 1,无 PoP。
///
/// 和传输层无关:只要一个 xfer(端点名, 请求字节) -> 响应字节。
/// 真机上是 BLE 写+读(ProtocommBLE),与小程序 utils/prov.js 逐字段对齐
/// (握手字段号、密钥流消耗顺序完全一致,对照 ESP-IDF v5.5
/// protocomm/src/security/security1.c 与 network_provisioning 1.0.2)。
actor ProvisionSession {
    // constants.proto 的 Status
    static let statusText = ["成功", "安全方案不匹配", "协议错误", "会话太多", "参数错误", "设备内部错误", "加密错误", "会话无效"]

    enum Outcome: Equatable {
        case connecting
        case connected(ip: String)
        case failed(reason: String)   // "auth" | "notfound"
        case timeout
    }

    private let xfer: (String, Data) async throws -> Data
    private var ctr: AesCtr?          // 整个会话唯一一条 CTR 密钥流,两个方向、所有端点共用
    private var broken = false        // 传输出错 = 两端密钥流位置可能已错开,只能断开重来
    private var needReset = false     // 上次连 WiFi 失败:设备拒绝再次 Apply,要先发 ctrl reset
    private var inFlight = false      // 密钥流按调用顺序消耗,请求绝不能交叠(actor + 显式互斥双保险)

    init(xfer: @escaping (String, Data) async throws -> Data) { self.xfer = xfer }

    private func claim() throws {
        if inFlight { throw ProvError.session("上一个请求还没结束") }
        if broken { throw ProvError.session("加密会话已失效,请重新连接手办") }
        inFlight = true
    }
    private func release() { inFlight = false }

    private func statusText(_ st: UInt64) -> String {
        Self.statusText.indices.contains(Int(st)) ? Self.statusText[Int(st)] : String(st)
    }

    private func checkStatus(_ v: PBValue?, _ what: String) throws {
        let st = v?.varintValue ?? 0
        if st != 0 { throw ProvError.status("\(what)被手办拒绝:\(statusText(st))") }
    }

    // 加密请求 -> 发 -> 解密响应。设备回的是正常响应(哪怕 status 非 0),流就还对得上;
    // 只有这一步失败才算错位。
    private func secure(_ ep: String, _ fields: [PBField]) async throws -> [UInt32: PBValue] {
        guard let ctr else { throw ProvError.session("加密会话还没建立") }
        do {
            let req = ctr.update(MiniPB.encode(fields))
            let resp = try await xfer(ep, req)
            return try MiniPB.decode(ctr.update(resp))
        } catch {
            broken = true
            throw error
        }
    }

    // NetworkConfigPayload:发 fields,取回响应里 respField 那个子消息
    private func config(_ fields: [PBField], _ respField: UInt32, _ what: String) async throws -> [UInt32: PBValue] {
        let outer = try await secure("prov-config", fields)
        guard let body = outer[respField]?.bytesValue else {
            throw ProvError.session("手办回复格式不对(\(what))")
        }
        let r = try MiniPB.decode(body)
        try checkStatus(r[1], what)
        return r
    }

    // SessionData 响应 -> 取出 Sec1Payload 里的 sr0(21)/ sr1(23)
    private func sec1Resp(_ buf: Data, _ field: UInt32) throws -> [UInt32: PBValue] {
        let d = try MiniPB.decode(buf)
        guard d[2]?.varintValue == 1 else { throw ProvError.session("手办的安全方案不是 Security 1") }
        let sec1 = try MiniPB.decode(d[11]?.bytesValue ?? Data())
        guard let body = sec1[field]?.bytesValue else { throw ProvError.session("手办握手回复格式不对") }
        let r = try MiniPB.decode(body)
        try checkStatus(r[1], "加密握手")
        return r
    }

    /// proto-ver 明文端点:写任意非空字节,读回 JSON。用来确认固件是 Sec1、不要 PoP。
    /// (明文阶段不消耗密钥流,失败不算 broken —— 与 prov.js 一致)
    func protoVer() async throws {
        try claim(); defer { release() }
        let raw: Data
        do { raw = try await xfer("proto-ver", MiniPB.utf8("---")) } catch { throw error }
        guard
            let obj = (try? JSONSerialization.jsonObject(with: raw)) as? [String: Any],
            let prov = obj["prov"] as? [String: Any]
        else { throw ProvError.session("手办固件信息不是预期的 JSON") }
        let ver = (prov["sec_ver"] as? NSNumber)?.intValue
        guard ver == 1 else { throw ProvError.session("手办固件的安全版本是 \(prov["sec_ver"] ?? "?"),本 App 只支持 1") }
    }

    /// Security 1 握手。私钥在本方法内用系统安全随机生成(小程序里由 wx.getRandomValues 生成)。
    func handshake() async throws {
        try claim(); defer { release() }
        do {
            let kp = X25519.generate()
            let cliPub = kp.publicKeyData
            // Cmd0:SessionData{sec_ver=1, sec1{sc0{client_pubkey}}}
            let req0 = MiniPB.encode([
                PBField(2, .varint(1)),
                PBField(11, .message([PBField(20, .message([PBField(1, .bytes(cliPub))]))])),
            ])
            let r0 = try sec1Resp(try await xfer("prov-session", req0), 21)
            guard let devPub = r0[2]?.bytesValue, devPub.count == 32,
                  let devRand = r0[3]?.bytesValue, devRand.count == 16 else {
                throw ProvError.session("手办握手回复格式不对")
            }

            // 无 PoP:AES 密钥就是 X25519 共享密钥本身;初始计数器 = device_random
            let shared = try X25519.sharedSecret(priv: kp, peerPublic: devPub)
            let stream = try AesCtr(key: shared, iv: devRand)
            ctr = stream

            // Cmd1:client_verify = 密钥流[0,32) XOR 设备公钥
            let req1 = MiniPB.encode([
                PBField(2, .varint(1)),
                PBField(11, .message([
                    PBField(1, .varint(2)),
                    PBField(22, .message([PBField(2, .bytes(stream.update(devPub)))])),
                ])),
            ])
            let r1 = try sec1Resp(try await xfer("prov-session", req1), 23)
            // 设备证明 = 密钥流[32,64) XOR 我方公钥
            let check = stream.update(r1[3]?.bytesValue ?? Data())
            guard check.count == 32, [UInt8](check) == [UInt8](cliPub) else {
                throw ProvError.session("手办身份校验失败")
            }
        } catch {
            broken = true
            throw error
        }
    }

    /// ssid / pass 都是 UTF-8 字节。字段 12(cmd_set_wifi_config)必须在场
    func setWifi(ssid: String, pass: String) async throws {
        try claim(); defer { release() }
        _ = try await config([
            PBField(1, .varint(2)),
            PBField(12, .message([
                PBField(1, .bytes(MiniPB.utf8(ssid))),
                PBField(2, .bytes(MiniPB.utf8(pass))),
            ])),
        ], 13, "发送 WiFi 信息")
    }

    func apply() async throws {
        try claim(); defer { release() }
        _ = try await config([PBField(1, .varint(4)), PBField(14, .message([]))], 15, "应用 WiFi 配置")
    }

    func getStatus() async throws -> Outcome {
        try claim(); defer { release() }
        // msg=GetWifiStatus(0) 不上线,只剩空的 cmd_get_wifi_status —— 请求不能是 0 字节
        let r = try await config([PBField(10, .message([]))], 11, "查询状态")
        let state = r[2]?.varintValue ?? 0               // Connected=0 在线上是缺省的
        if state == 1 { return .connecting }
        if state == 0 {
            let inner = try MiniPB.decode(r[11]?.bytesValue ?? Data())
            return .connected(ip: MiniPB.ascii(inner[1]?.bytesValue ?? Data()))
        }
        // 3=ConnectionFailed(2=Disconnected 设备实际不发)。原因缺省按 proto3 当 0=AuthError
        return .failed(reason: r[10]?.varintValue == 1 ? "notfound" : "auth")
    }

    /// NetworkCtrlPayload{msg=CmdCtrlWifiReset(1), cmd_ctrl_wifi_reset{}};status 在外层字段 2
    func ctrlReset() async throws {
        try claim(); defer { release() }
        let r = try await secure("prov-ctrl", [PBField(1, .varint(1)), PBField(11, .message([]))])
        try checkStatus(r[2], "重置 WiFi 状态")
    }

    /// 完整一轮:(必要时先 reset)-> Set -> Apply -> 每 intervalMs 查一次状态直到出结果。
    /// 结果多一种 timeout:设备还在连,可能在按"非密码类原因"不停重试。
    func provision(ssid: String, pass: String, timeoutMs: Int = 30000, intervalMs: Int = 1000,
                   onStep: @escaping @Sendable (String) -> Void) async throws -> Outcome {
        if needReset {
            onStep("重置手办的 WiFi 状态…")
            try await ctrlReset()
            needReset = false
        }
        onStep("发送 WiFi 信息…")
        try await setWifi(ssid: ssid, pass: pass)
        try await apply()
        onStep("手办正在连 WiFi…")
        let t0 = Date()
        while true {
            try await Task.sleep(nanoseconds: UInt64(intervalMs) * 1_000_000)
            let s = try await getStatus()
            if case .failed = s { needReset = true }
            if case .connecting = s {} else { return s }
            if Date().timeIntervalSince(t0) * 1000 >= Double(timeoutMs) { return .timeout }
        }
    }
}
