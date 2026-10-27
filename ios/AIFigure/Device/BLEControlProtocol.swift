import Foundation

struct BLEDeviceStatus: Decodable {
    let wifi: Bool
    let ready: Bool
    let usb: Bool
    let volume: Int
    let ssid: String
    let ip: String
    let state: String
    let firmware: String
    let host: String
    let port: Int
    let switching: Bool
    var label: String {
        if switching { return "正在切换网络" }
        if !wifi { return "蓝牙已连接 · 离线可用" }
        if !ready { return "已联网 · 互动服务未连接" }
        switch state {
        case "REC": return "正在听"
        case "WAIT": return "处理中"
        case "PLAY": return "正在回应"
        default: return "可互动"
        }
    }
}

enum BLEControlProtocol {
    static func request(op: String, key: String, id: String? = nil, fields: [String: Any] = [:]) throws -> Data {
        guard key.count == 64, key.allSatisfy({ "0123456789abcdef".contains($0) }),
              ["auth", "status", "gateway", "result", "identify", "volume", "wifi", "server"].contains(op),
              Set(fields.keys).isSubset(of: ["s", "p", "n"]) else { throw ProvError.session("蓝牙请求无效") }
        var value = fields
        value["o"] = op; value["k"] = key
        if let id {
            guard id.count == 32, id.allSatisfy({ "0123456789abcdef".contains($0) }) else { throw ProvError.session("操作编号无效") }
            value["i"] = id
        }
        let data = try JSONSerialization.data(withJSONObject: value, options: [.sortedKeys, .withoutEscapingSlashes])
        guard data.count <= 384 else { throw ProvError.session("网络信息过长") }
        return data
    }
    static func reply(_ data: Data) throws -> [String: Any] {
        guard data.count <= 2048, let value = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              (value["v"] as? Int) == 1, let result = value["result"] as? String,
              ["accepted", "running", "completed", "failed", "rejected", "unknown", "confirm"].contains(result)
        else { throw ProvError.session("手办回复无效，请重新连接") }
        return value
    }
    static func failure(_ code: String) -> String {
        switch code {
        case "not_owner": return "这台手办已由另一部手机授权"
        case "pairing_busy": return "另一部手机正在连接，请稍后重试"
        case "device_busy": return "手办正在互动，请结束后重试"
        case "wifi_failed_restored": return "新网络连接失败，已恢复原网络配置"
        case "storage_failed": return "主板未能保存设置，请重试"
        case "invalid_request": return "请检查网络名称、密码和服务设置"
        default: return "手办未完成操作（\(code)）"
        }
    }
}
