import SwiftUI
import AVFoundation
import UIKit

struct DeviceQRScanner: UIViewControllerRepresentable {
    let onCode: (String) -> Void
    func makeUIViewController(context: Context) -> DeviceScannerController { DeviceScannerController(onCode: onCode) }
    func updateUIViewController(_ controller: DeviceScannerController, context: Context) {}
}

final class DeviceScannerController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    private let capture = AVCaptureSession()
    private let queue = DispatchQueue(label: "com.aiapp.device-code-camera")
    private let onCode: (String) -> Void
    private var preview: AVCaptureVideoPreviewLayer?
    private var delivered = false
    private var configured = false
    private var dismissed = false

    init(onCode: @escaping (String) -> Void) { self.onCode = onCode; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }
    override func viewDidLoad() {
        super.viewDidLoad(); view.backgroundColor = .black
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: configure()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { allowed in
                DispatchQueue.main.async {
                    guard !self.dismissed else { return }
                    if allowed { self.configure() } else { self.showMessage("请允许相机访问，或返回后手动连接") }
                }
            }
        default: showMessage("请在系统设置中允许相机访问，或返回后手动连接")
        }
    }
    override func viewDidLayoutSubviews() { super.viewDidLayoutSubviews(); preview?.frame = view.bounds }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dismissed = true
        queue.async { self.capture.stopRunning() }
    }
    private func showMessage(_ text: String) {
        let label = UILabel(); label.text = text; label.numberOfLines = 0
        label.textColor = .white; label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(label)
        NSLayoutConstraint.activate([label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24), label.centerYAnchor.constraint(equalTo: view.centerYAnchor)])
    }
    private func configure() {
        guard !configured, !dismissed else { return }; configured = true
        guard let camera = AVCaptureDevice.default(for: .video), let input = try? AVCaptureDeviceInput(device: camera),
              capture.canAddInput(input) else { showMessage("相机暂不可用，请返回后手动连接"); return }
        capture.addInput(input)
        let output = AVCaptureMetadataOutput()
        guard capture.canAddOutput(output) else { showMessage("无法扫描，请返回后手动连接"); return }
        capture.addOutput(output); output.setMetadataObjectsDelegate(self, queue: .main); output.metadataObjectTypes = [.qr]
        let layer = AVCaptureVideoPreviewLayer(session: capture); layer.videoGravity = .resizeAspectFill
        preview = layer; view.layer.addSublayer(layer); layer.frame = view.bounds
        queue.async { self.capture.startRunning() }
    }
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput objects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard !delivered, !dismissed, let code = objects.compactMap({ ($0 as? AVMetadataMachineReadableCodeObject)?.stringValue }).first else { return }
        delivered = true; queue.async { self.capture.stopRunning() }; onCode(code)
    }
}
