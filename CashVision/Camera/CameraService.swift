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
        await withCheckedContinuation { continuation in
            videoQueue.async {
                self.configureSession()
                continuation.resume()
            }
        }
    }

    func start() {
        videoQueue.async {
            guard self.session.isRunning == false else { return }
            self.session.startRunning()
            DispatchQueue.main.async { self.status = .running }
        }
    }

    func stop() {
        videoQueue.async {
            if self.session.isRunning {
                self.session.stopRunning()
                AppLogger.camera.notice("Camera session stopped")
            }
        }
    }

    func setDelegate(_ delegate: AVCaptureVideoDataOutputSampleBufferDelegate) {
        guard let output = frameOutput else { return }
        videoQueue.async {
            output.setSampleBufferDelegate(delegate, queue: self.videoQueue)
        }
    }

    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .high
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
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
                    frameOutput = output
                }
                isConfigured = true
                AppLogger.camera.info("Camera session configured")
            } catch {
                AppLogger.camera.error("Camera config failed: \(error.localizedDescription)")
                DispatchQueue.main.async { self.status = .failed(error.localizedDescription) }
            }
        } else {
            DispatchQueue.main.async { self.status = .failed("No camera available") }
        }
        session.commitConfiguration()
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
