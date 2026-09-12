import Foundation
@preconcurrency import AVFoundation
import CoreVideo

@MainActor
final class CameraFrameDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let recognition: BanknoteRecognitionService
    let onResult: @MainActor (RecognitionResult?) -> Void
    private var lastEmit: Date = .distantPast

    init(recognition: BanknoteRecognitionService, onResult: @escaping @MainActor (RecognitionResult?) -> Void) {
        self.recognition = recognition
        self.onResult = onResult
    }

    nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        Task { @MainActor [weak self] in
            guard let self else { return }
            await self.recognition.processFrame(pixelBuffer)
            let now = Date()
            if now.timeIntervalSince(self.lastEmit) >= 0.3 {
                self.lastEmit = now
                self.onResult(self.recognition.lastResult)
            }
        }
    }
}
