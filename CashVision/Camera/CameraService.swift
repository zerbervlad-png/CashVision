import Foundation
import AVFoundation
import UIKit
import Combine
import Observation

@MainActor
@Observable
final class CameraService: NSObject {
    enum Status: Equatable {
        case unauthorized
        case notDetermined
        case ready
        case running
        case failed(String)
    }

    private(set) var status: Status = .notDetermined
    private(set) var permissionGranted: Bool = false
    private(set) var isTorchOn: Bool = false
    private let session = AVCaptureSession()
    private let videoQueue = DispatchQueue(label: "ai.cashvision.camera.queue", qos: .userInitiated)
    private var frameOutput: AVCaptureVideoDataOutput?
    private var isConfigured = false

    var captureSession: AVCaptureSession { session }
    var previewLayer: AVCaptureVideoPreviewLayer {
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        return layer
    }

    override init() {
        super.init()
    }

    func checkPermission() async -> Status {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionGranted = true
            status = .ready
            return .ready
        case .notDetermined:
            status = .notDetermined
            return .notDetermined
        case .denied, .restricted:
            permissionGranted = false
            status = .unauthorized
            return .unauthorized
        @unknown default:
            status = .unauthorized
            return .unauthorized
        }
    }

    func requestPermission() async -> Bool {
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        permissionGranted = granted
        status = granted ? .ready : .unauthorized
        return granted
    }

    func configure() async {
        guard status == .ready || status == .running else { return }
        let session = self.session
        let result: ConfigureResult = await withCheckedContinuation { continuation in
            videoQueue.async {
                let res = Self.configureSession(session)
                continuation.resume(returning: res)
            }
        }
        switch result {
        case .success(let output):
            self.frameOutput = output
            self.isConfigured = true
            AppLogger.camera.info("Camera session configured")
        case .failure(let message):
            self.status = .failed(message)
        case .noCamera:
            self.status = .failed("No camera available")
        }
    }

    func start() {
        let session = self.session
        videoQueue.async {
            guard session.isRunning == false else { return }
            session.startRunning()
            DispatchQueue.main.async { self.status = .running }
        }
    }

    func stop() {
        let session = self.session
        videoQueue.async {
            if session.isRunning {
                session.stopRunning()
                AppLogger.camera.notice("Camera session stopped")
            }
        }
    }

    func setDelegate(_ delegate: AVCaptureVideoDataOutputSampleBufferDelegate) {
        guard let output = frameOutput else { return }
        let queue = self.videoQueue
        videoQueue.async {
            output.setSampleBufferDelegate(delegate, queue: queue)
        }
    }

    func setTorch(enabled: Bool) async {
        guard let device = AVCaptureDevice.default(for: .video),
              device.hasTorch else {
            AppLogger.camera.notice("Torch not available on this device")
            return
        }
        do {
            try device.lockForConfiguration()
            try device.setTorchModeOn(level: enabled ? 1.0 : 0.0)
            device.unlockForConfiguration()
            self.isTorchOn = enabled
            AppLogger.camera.info("Torch \(enabled ? "on" : "off")")
        } catch {
            AppLogger.camera.error("Torch toggle failed: \(error.localizedDescription)")
        }
    }

    func toggleTorch() async {
        await setTorch(enabled: !isTorchOn)
    }

    private enum ConfigureResult {
        case success(AVCaptureVideoDataOutput)
        case failure(String)
        case noCamera
    }

    private nonisolated static func configureSession(_ session: AVCaptureSession) -> ConfigureResult {
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        session.sessionPreset = .high
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            return .noCamera
        }
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
            }
            let output = AVCaptureVideoDataOutput()
            output.alwaysDiscardsLateVideoFrames = true
            output.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
            ]
            if session.canAddOutput(output) {
                session.addOutput(output)
                return .success(output)
            }
            return .failure("Could not add video output")
        } catch {
            AppLogger.camera.error("Camera config failed: \(error.localizedDescription)")
            return .failure(error.localizedDescription)
        }
    }

    func handleAppBackground() {
        stop()
    }

    func handleAppForeground() {
        if permissionGranted {
            start()
        }
    }
}
