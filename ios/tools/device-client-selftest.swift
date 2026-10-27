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
        LabURLProtocol.failureStatus = 401
        do { _ = try await client.status(); fatalError("Unauthorized request accepted") }
        catch let error as LabClientError { assert(error.status == 401) }
        print("Device client: URL boundary, auth header, JSON decoding, idempotency and unauthorized response passed")
    }
}
