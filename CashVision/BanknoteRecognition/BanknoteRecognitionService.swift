import Foundation
import AVFoundation
import CoreImage
import Vision
import CoreML
import Observation

@MainActor
@Observable
final class BanknoteRecognitionService {
    private let detector: BanknoteDetectorModel
    private let classifier: BanknoteClassifierModel
    private let qualityModel: BanknoteQualityModel
    private let frameThrottler: FrameThrottler

    private(set) var lastResult: RecognitionResult?
    private(set) var isProcessing = false

    init(
        detector: BanknoteDetectorModel = StubBanknoteDetector(),
        classifier: BanknoteClassifierModel = StubBanknoteClassifier(),
        qualityModel: BanknoteQualityModel = StubBanknoteQualityModel(),
        inferenceFPS: Double = 12
    ) {
        self.detector = detector
        self.classifier = classifier
        self.qualityModel = qualityModel
        self.frameThrottler = FrameThrottler(targetFPS: inferenceFPS)
    }

    func processFrame(_ buffer: CVPixelBuffer) async {
        guard frameThrottler.shouldProcess(), !isProcessing else { return }
        isProcessing = true
        defer { isProcessing = false }

        do {
            let detections = try await detector.detect(in: buffer)
            let quality = try await qualityModel.assess(buffer: buffer)

            var recognized: [RecognizedBanknote] = []
            for detection in detections where detection.confidence >= 0.4 {
                let classification = try? await classifier.classify(buffer: buffer)
                recognized.append(
                    RecognizedBanknote(
                        denomination: classification?.denomination ?? Denomination(currency: .rub, value: 0),
                        side: classification?.side ?? .front,
                        orientation: classification?.orientation ?? .up,
                        boundingBox: detection.boundingBox,
                        confidence: min(detection.confidence, classification?.confidence ?? 1),
                        qualityScore: quality.overallScore,
                        isPartial: detection.boundingBox.width < 0.4 || detection.boundingBox.height < 0.4
                    )
                )
            }
            let result = RecognitionResult(
                banknotes: recognized,
                quality: quality,
                timestamp: Date()
            )
            self.lastResult = result
            AppLogger.vision.info("Recognition: \(recognized.count) banknotes, score \(quality.overallScore)")
        } catch {
            AppLogger.vision.error("Recognition pipeline failed: \(error.localizedDescription)")
        }
    }

    func setInferenceFPS(_ fps: Double) {
        frameThrottler.setTargetFPS(fps)
    }
}

struct RecognitionResult: Equatable, Sendable {
    let banknotes: [RecognizedBanknote]
    let quality: BanknoteQualityAssessment
    let timestamp: Date
}

final class FrameThrottler: @unchecked Sendable {
    private var targetFPS: Double
    private var lastProcessed: Date = .distantPast
    private let lock = NSLock()

    init(targetFPS: Double) { self.targetFPS = targetFPS }

    func setTargetFPS(_ fps: Double) {
        lock.lock(); defer { lock.unlock() }
        targetFPS = max(1, min(fps, 30))
    }

    func shouldProcess(now: Date = Date()) -> Bool {
        lock.lock(); defer { lock.unlock() }
        let interval = 1.0 / targetFPS
        if now.timeIntervalSince(lastProcessed) >= interval {
            lastProcessed = now
            return true
        }
        return false
    }
}
