import Foundation
import CoreBluetooth

/// protocomm 的 BLE 传输,对齐小程序 utils/ble.js:
/// 一次请求 = 往端点特征值**写一次**整条消息(write with response),再**读一次**
/// 同一个特征值拿响应;没有 notify、没有分片。所以:
///   - 每条消息必须一次 ATT 写完(iOS 自己协商 MTU,无需手动调大)
///   - 空写会被设备忽略,读回来是上一次的旧响应 —— 绝不发 0 字节
///   - 同一时刻只能有一个请求在路上(ProvisionSession 已串行化,这里再兜一层)
final class ProtocommBLE: NSObject {
    static let serviceUUID = CBUUID(string: "10624C9A-F2AA-4CA8-8594-9CD3CC78DB3F")
    static let namePrefix = "AIFIG_"
    static let xferTimeout: TimeInterval = 8
    static let connectTimeout: TimeInterval = 10

    struct Found: Identifiable, Equatable {
        let id: UUID
        let name: String
        let rssi: Int
    }

    // 端点名 -> 16 bit id;特征值 UUID = 服务 UUID 第一段的第 5~8 个十六进制字符换成它
    enum Endpoint: String {
        case provCtrl = "FF4F", provScan = "FF50", provSession = "FF51", provConfig = "FF52", protoVer = "FF53"
        var cbuuid: CBUUID { CBUUID(string: "1062" + rawValue + String(Self.serviceUUID.uuidString.dropFirst(8))) }
    }

    /// prov.js 用的端点字符串名 -> 本类枚举(ProvisionSession 的 xfer 闭包拿字符串)
    static let endpointByName: [String: Endpoint] = [
        "prov-ctrl": .provCtrl, "prov-scan": .provScan, "prov-session": .provSession,
        "prov-config": .provConfig, "proto-ver": .protoVer,
    ]

    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: nil)   // 主队列:与续体/定时器同一串行上下文
    }

    private var central: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var chars: [Endpoint: CBCharacteristic] = [:]
    private var onFound: ((Found) -> Void)?
    private var scanning = false
    private var disconnectHandler: (() -> Void)?

    // 挂起的操作(同一时刻至多一个)
    private var connectCont: CheckedContinuation<Void, Error>?
    private var serviceCont: CheckedContinuation<Void, Error>?
    private var writeCont: CheckedContinuation<Void, Error>?
    private var readCont: CheckedContinuation<Data, Error>?
    private var readyCont: CheckedContinuation<Void, Never>?
    private var deadline: DispatchWorkItem?

    // MARK: 对外 API

    /// 首次访问会触发系统蓝牙权限弹窗;等状态可用(poweredOn)或抛出可读错误
    func waitReady() async throws {
        if central.state == .poweredOn { return }
        await withCheckedContinuation { (c: CheckedContinuation<Void, Never>) in readyCont = c }
        if let e = stateError() { throw e }
    }

    func stateError() -> Error? {
        switch central.state {
        case .poweredOn: return nil
        case .poweredOff: return ProvError.ble("手机蓝牙没打开,请打开蓝牙后重试")
        case .unauthorized: return ProvError.ble("没有蓝牙权限:请在系统设置里允许本 App 使用蓝牙")
        case .unsupported: return ProvError.ble("这台手机不支持低功耗蓝牙")
        default: return ProvError.ble("蓝牙还没就绪,稍等一下再试")
        }
    }

    /// onFound 每发现/更新一台手办调一次(已按服务 UUID 或名字前缀过滤)
    func startScan(_ onFound: @escaping (Found) -> Void) throws {
        if let e = stateError() { throw e }
        self.onFound = onFound
        scanning = true
        // 不按服务过滤:名字前缀也算,万一哪台手机拿不到广播里的 128 bit UUID
        central.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
    }

    func stopScan() {
        if scanning { central.stopScan() }
        scanning = false
    }

    /// 连接并找齐端点。onDisconnect:意外断开时回调(加密会话随之作废)
    func connect(_ id: UUID, onDisconnect: @escaping () -> Void) async throws {
        try await waitReady()
        stopScan()
        disconnectHandler = onDisconnect
        guard let p = central.retrievePeripherals(withIdentifiers: [id]).first else {
            throw ProvError.ble("连接手办失败,请靠近一点再试")
        }
        peripheral = p
        p.delegate = self
        try await withTimeout(Self.connectTimeout, "连接超时,请靠近手办再试") { self.central.connect(p) }
        // 读写前必须先拿过服务和特征值
        p.discoverServices([Self.serviceUUID])
        try await withTimeout(Self.connectTimeout, "这个设备上找不到配网服务:是不是没进配网模式,或固件太旧?") {}
        guard chars[.protoVer] != nil, chars[.provSession] != nil,
              chars[.provConfig] != nil, chars[.provCtrl] != nil else {
            throw ProvError.ble("这个设备上找不到配网服务:是不是没进配网模式,或固件太旧?")
        }
    }

    /// 写整条请求,再读回响应
    func xfer(_ ep: Endpoint, _ bytes: Data) async throws -> Data {
        guard let p = peripheral, let ch = chars[ep] else { throw ProvError.ble("蓝牙连接已断开") }
        if bytes.isEmpty { throw ProvError.ble("不能发空消息") }     // 设备会忽略空写,读回旧数据
        guard writeCont == nil, readCont == nil else { throw ProvError.ble("上一个请求还没结束") }
        let result: Data = try await withTimeout(Self.xferTimeout, "手办没有响应,请靠近后重新连接") {
            try await withCheckedThrowingContinuation { (w: CheckedContinuation<Void, Error>) in
                writeCont = w
                p.writeValue(bytes, for: ch, type: .withResponse)
            }
            return try await withCheckedThrowingContinuation { (r: CheckedContinuation<Data, Error>) in
                readCont = r
                p.readValue(for: ch)
            }
        }
        return result
    }

    /// 离开页面 / 结束 / 出错时调。什么状态下调都安全
    func close() {
        stopScan()
        failPending("已断开")
        disconnectHandler = nil
        if let p = peripheral {
            p.delegate = nil
            central.cancelPeripheralConnection(p)
        }
        peripheral = nil
        chars = [:]
    }

    // MARK: 超时与续体管理(全部回调都在主队列,无锁)

    private func withTimeout<T>(_ seconds: TimeInterval, _ message: String, _ body: @escaping () async throws -> T) async throws -> T {
        let item = DispatchWorkItem { [weak self] in self?.failPending(message) }
        deadline = item
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: item)
        defer {
            item.cancel()
            if deadline === item { deadline = nil }
        }
        return try await body()
    }

    private func failPending(_ message: String) {
        let e = ProvError.ble(message)
        for c in [writeCont, readCont] { c?.resume(throwing: e) }
        writeCont = nil; readCont = nil
        if let c = connectCont { connectCont = nil; c.resume(throwing: e) }
        if let c = serviceCont { serviceCont = nil; c.resume(throwing: e) }
    }
}

extension ProtocommBLE: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if let c = readyCont { readyCont = nil; c.resume() }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        guard let cb = onFound else { return }
        let name = peripheral.name ?? (advertisementData[CBAdvertisementDataLocalNameKey] as? String)
        let advertised = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID]
        let hit = (advertised ?? []).contains { $0 == Self.serviceUUID } || (name ?? "").hasPrefix(Self.namePrefix)
        guard hit else { return }
        cb(Found(id: peripheral.identifier, name: name ?? peripheral.identifier.uuidString, rssi: RSSI.intValue))
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if let c = connectCont { connectCont = nil; c.resume() }
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        failPending(error?.localizedDescription ?? "连接手办失败,请靠近一点再试")
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        failPending("蓝牙连接已断开")
        chars = [:]
        disconnectHandler?()
    }
}

extension ProtocommBLE: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let e = error { failPending(e.localizedDescription); return }
        guard let svc = peripheral.services?.first(where: { $0.uuid == Self.serviceUUID }) else {
            failPending("这个设备上找不到配网服务:是不是没进配网模式,或固件太旧?"); return
        }
        let wanted = Endpoint.allCases.map(\.cbuuid)
        peripheral.discoverCharacteristics(wanted, for: svc)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let e = error { failPending(e.localizedDescription); return }
        for ch in service.characteristics ?? [] {
            for ep in Endpoint.allCases where ch.uuid == ep.cbuuid { chars[ep] = ch }
        }
        if let c = serviceCont { serviceCont = nil; c.resume() }   // 四个必需端点在 connect() 里统一校验
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let c = writeCont else { return }
        writeCont = nil
        error == nil ? c.resume() : c.resume(throwing: error!)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let c = readCont else { return }
        readCont = nil
        if let e = error { c.resume(throwing: e) } else { c.resume(returning: characteristic.value ?? Data()) }
    }
}
