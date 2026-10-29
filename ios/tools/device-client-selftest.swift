import Foundation

final class LabURLProtocol: URLProtocol {
    static var failureStatus: Int?
    static var telemetryState = "IDLE"
    static var busy = false
    static let token = String(repeating: "x", count: 48)
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        assert(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(Self.token)")
        let path = request.url!.path
        let response: String
        if let code = Self.failureStatus {
            response = "{\"error\":{\"message\":\"access denied\"}}"
            deliver(response, code: code); return
        }
        if path == "/lab/v1/status" {
            response = """
            {"data":{"device_id":"test","device_online":true,"firmware":"test","supports_identify":true,"can_identify":true,"telemetry_fresh":true,"telemetry_at":1,"pending_operation_id":null,"busy":\(Self.busy),"service_ready":true,"telemetry":{"state":"\(Self.telemetryState)","usb_present":true,"battery_mv":1200,"battery_validation":"unverified","battery_percent":null,"charging":null,"rssi":-40}}}
            """
        } else if path == "/lab/v1/chat" {
            assert(request.url?.query?.contains("since=3") == true)
            response="{\"data\":{\"turns\":[],\"revision\":3,\"oldest\":null,\"has_older\":false,\"device_id\":\"test\",\"reset\":false}}"
        } else {
            if request.httpMethod == "POST" {
                assert(request.value(forHTTPHeaderField: "Idempotency-Key") != nil)
                assert(request.value(forHTTPHeaderField: "Content-Type") == (path == "/lab/v1/voice" ? "application/octet-stream" : "application/json"))
            }
            response = "{\"data\":{\"id\":\"00000000000000000000000000000001\",\"status\":\"completed\",\"code\":\"\",\"created\":1,\"updated\":2}}"
        }
        deliver(response, code: 200)
    }
    func deliver(_ body: String, code: Int) {
        client?.urlProtocol(self, didReceive: HTTPURLResponse(url: request.url!, statusCode: code, httpVersion: nil, headerFields: nil)!, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(body.utf8)); client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}

@main struct DeviceClientSelftest {
    static func main() async throws {
        for allowed in ["http://192.168.137.1:8795", "http://10.1.2.3", "https://test.example"] {
            _ = try DeviceLabClient.validatedBase(allowed)
        }
        for invalid in ["http://example.com", "http://1.2.3.4", "http://user:password@10.1.2.3", "http://10.1.2.3/a", "http://10.1.2.3?token=x", "http://192.168.999.1"] {
            do { _ = try DeviceLabClient.validatedBase(invalid); fatalError("Invalid endpoint accepted") }
            catch is LabClientError {}
        }
        let config = URLSessionConfiguration.ephemeral; config.protocolClasses = [LabURLProtocol.self]
        let client = try DeviceLabClient(address: "http://192.168.137.1:8795", token: LabURLProtocol.token, session: URLSession(configuration: config))
        assert(SystemVolumePolicy.target(old:0.25,new:0.5,foreground:true,recording:false)==50)
        assert(SystemVolumePolicy.target(old:0.5,new:0,foreground:true,recording:false)==0)
        assert(SystemVolumePolicy.target(old:0.5,new:1,foreground:true,recording:false)==100)
        assert(SystemVolumePolicy.target(old:0.5,new:0.75,foreground:false,recording:false)==nil)
        assert(SystemVolumePolicy.target(old:0.5,new:0.75,foreground:true,recording:true)==nil)
        assert(SystemVolumePolicy.target(old:0.5,new:0.5,foreground:true,recording:false)==nil)
        let status = try await client.status()
        assert(status.stateLabel == "可互动" && status.telemetry?.batteryPercent == nil)
        let lost = LabOperation(id:"previous",status:"unknown",code:"device_disconnected",created:1,updated:2,kind:"voice")
        assert(status.canResumeAfterReconnect(lost))
        let timedOut = LabOperation(id:"previous",status:"unknown",code:"receipt_timeout",created:1,updated:2,kind:"voice")
        assert(!status.canResumeAfterReconnect(timedOut))
        LabURLProtocol.busy = true; LabURLProtocol.telemetryState = "WAIT"
        let preparing = try await client.status(); assert(preparing.stateLabel == "处理中")
        assert(!preparing.canResumeAfterReconnect(lost))
        LabURLProtocol.telemetryState = "PLAY"
        let playing = try await client.status(); assert(playing.stateLabel == "正在回应")
        assert(!playing.canResumeAfterReconnect(lost))
        LabURLProtocol.busy = false; LabURLProtocol.telemetryState = "IDLE"
        let result = try await client.identify(key: UUID())
        assert(result.status == "completed" && !result.waiting)
        _ = try await client.operation(result.id)
        _ = try await client.voice(Data(repeating:0,count:16000), key:UUID())
        _ = try await client.interrupt(key:UUID())
        _ = try await client.volume(50,key:UUID())
        _ = try await client.text("测试文字",key:UUID())
        let history=try await client.chat(since:3); assert(history.revision==3)
        let row=LabChatTurn(id:"turn-one",position:1,source:"device_voice",operationId:nil,created:1,updated:2,revision:2,userText:"测试问题",userStatus:"final",assistantText:"测试回复",assistantStatus:"interrupted")
        let receipt=LabChatTurn(id:"receipt",position:2,source:"phone_text",operationId:"op-1",created:100,updated:101,revision:1,userText:"你好",userStatus:"final",assistantText:"",assistantStatus:"streaming")
        assert(PendingTextReceipt.matches(receipt,text:"你好",created:Date(timeIntervalSince1970:100),operationID:"op-1",currentOperationID:nil))
        assert(!PendingTextReceipt.matches(receipt,text:"你好",created:Date(timeIntervalSince1970:100),operationID:"op-2",currentOperationID:nil))
        assert(!PendingTextReceipt.matches(receipt,text:"再见",created:Date(timeIntervalSince1970:100),operationID:"op-1",currentOperationID:nil))
        assert(PendingTextReceipt.matches(receipt,text:"你好",created:Date(timeIntervalSince1970:99),operationID:nil,currentOperationID:nil))
        assert(!PendingTextReceipt.matches(receipt,text:"你好",created:Date(timeIntervalSince1970:1000),operationID:nil,currentOperationID:nil))
        let page=LabChatPage(turns:[row],revision:2,oldest:1,hasOlder:false,deviceId:"test",reset:false)
        var cache=ChatHistoryCache();cache.merge(page);cache.merge(page)
        assert(cache.turns.count==1 && cache.turns[0].assistantNote=="已打断")
        let scope="test-only-"+UUID().uuidString
        try cache.save(scope:scope)
        let saved=try ChatHistoryCache.load(scope:scope);assert(saved.turns[0].userText=="测试问题")
        try FileManager.default.removeItem(at:ChatHistoryCache.url(scope:scope))
        LabURLProtocol.failureStatus = 401
        do { _ = try await client.status(); fatalError("Unauthorized request accepted") }
        catch let error as LabClientError { assert(error.status == 401) }
        print("Device client: URL boundary, auth header, JSON decoding, idempotency and unauthorized response passed")
    }
}
