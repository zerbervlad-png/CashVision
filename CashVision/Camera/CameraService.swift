import Foundation
@preconcurrency import AVFoundation
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
    @ObservationIgnored private var torchDevice: AVCaptureDevice?
    @ObservationIgnored private var lifecycleCancellables: Set<AnyCancellable> = []

    var captureSession: AVCaptureSession { session }

    override init() {
        super.init()
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.handleAppBackground() }
            .store(in: &lifecycleCancellables)
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.handleAppForeground() }
            .store(in: &lifecycleCancellables)
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
        guard !isConfigured, status == .ready || status == .running else { return }
        let session = UncheckedSendable(value: self.session)
        let result: ConfigureResult = await withCheckedContinuation { (continuation: CheckedContinuation<ConfigureResult, Never>) in
            videoQueue.async {
                let res = Self.configureSession(session.value)
                continuation.resume(returning: res)
            }
        }
        switch result {
        case .success(let output):
            self.frameOutput = output
            self.isConfigured = true
            self.torchDevice = AVCaptureDevice.default(for: .video)
            AppLogger.camera.info("Camera session configured")
        case .failure(let message):
            self.status = .failed(message)
        case .noCamera:
            self.status = .failed("No camera available")
        }
    }

    func start() {
        let session = UncheckedSendable(value: self.session)
        let queue = self.videoQueue
        queue.async { [weak self] in
            guard session.value.isRunning == false else { return }
            session.value.startRunning()
            Task { @MainActor [weak self] in self?.status = .running }
        }
    }

    func stop() {
        let session = UncheckedSendable(value: self.session)
        let queue = self.videoQueue
        queue.async {
            if session.value.isRunning {
                session.value.stopRunning()
                AppLogger.camera.notice("Camera session stopped")
            }
        }
    }

    func setDelegate(_ delegate: AVCaptureVideoDataOutputSampleBufferDelegate) {
        guard let frameOutput else { return }
        let output = UncheckedSendable(value: frameOutput)
        let delegate = UncheckedSendable(value: delegate)
        let queue = self.videoQueue
        videoQueue.async {
            output.value.setSampleBufferDelegate(delegate.value, queue: queue)
        }
    }

    func setTorch(enabled: Bool) async {
        guard let device = torchDevice ?? AVCaptureDevice.default(for: .video),
              device.hasTorch else {
            AppLogger.camera.notice("Torch not available on this device")
            return
        }
        do {
            try device.lockForConfiguration()
            defer { device.unlockForConfiguration() }
            if enabled {
                try device.setTorchModeOn(level: 1.0)
            } else {
                device.torchMode = .off
            }
            self.isTorchOn = enabled
            AppLogger.camera.info("Torch \(enabled ? "on" : "off")")
        } catch {
            AppLogger.camera.error("Torch toggle failed: \(error.localizedDescription)")
        }
    }

    func toggleTorch() async {
        await setTorch(enabled: !isTorchOn)
    }

    private struct UncheckedSendable<Value>: @unchecked Sendable {
        let value: Value
    }

    private enum ConfigureResult: @unchecked Sendable {
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
        if isTorchOn {
            Task { await setTorch(enabled: false) }
        }
        stop()
    }

    func handleAppForeground() {
        if permissionGranted {
            start()
        }
    }
}
