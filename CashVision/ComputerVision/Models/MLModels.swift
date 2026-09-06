import Foundation
import CoreML
import Vision

protocol BanknoteDetectorModel: Sendable {
    func detect(in pixelBuffer: CVPixelBuffer) async throws -> [BanknoteDetection]
}

protocol BanknoteClassifierModel: Sendable {
    func classify(buffer: CVPixelBuffer) async throws -> BanknoteClassification
}

protocol BanknoteQualityModel: Sendable {
    func assess(buffer: CVPixelBuffer) async throws -> BanknoteQualityAssessment
}

struct BanknoteDetection: Sendable {
    let boundingBox: NormalizedRect
    let confidence: Double
}

struct BanknoteClassification: Sendable {
    let denomination: Denomination
    let side: BanknoteSide
    let orientation: BanknoteOrientation
    let confidence: Double
}

struct BanknoteQualityAssessment: Sendable, Equatable {
    enum Issue: String, Sendable, Equatable {
        case lowLight
        case tooFar
        case obscured
        case blurry
        case skewed
        case glare
    }
    let overallScore: Double
    let issues: [Issue]
}

/// Stub-реализации моделей. На Mac с Xcode заменяются на скомпилированные .mlmodel классы.
final class StubBanknoteDetector: BanknoteDetectorModel {
    func detect(in pixelBuffer: CVPixelBuffer) async throws -> [BanknoteDetection] {
        return []
    }
}

final class StubBanknoteClassifier: BanknoteClassifierModel {
    func classify(buffer: CVPixelBuffer) async throws -> BanknoteClassification {
        throw AppError.recognitionFailed
    }
}

final class StubBanknoteQualityModel: BanknoteQualityModel {
    func assess(buffer: CVPixelBuffer) async throws -> BanknoteQualityAssessment {
        BanknoteQualityAssessment(overallScore: 1.0, issues: [])
    }
}
