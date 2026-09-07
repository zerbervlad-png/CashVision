import Foundation
import CoreML
import Vision

@MainActor
protocol BanknoteDetectorModel {
    func detect(in pixelBuffer: CVPixelBuffer) async throws -> [BanknoteDetection]
}

@MainActor
protocol BanknoteClassifierModel {
    func classify(buffer: CVPixelBuffer) async throws -> BanknoteClassification
}

@MainActor
protocol BanknoteQualityModel {
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

@MainActor
final class StubBanknoteDetector: BanknoteDetectorModel {
    func detect(in pixelBuffer: CVPixelBuffer) async throws -> [BanknoteDetection] {
        return []
    }
}

@MainActor
final class StubBanknoteClassifier: BanknoteClassifierModel {
    func classify(buffer: CVPixelBuffer) async throws -> BanknoteClassification {
        throw AppError.recognitionFailed
    }
}

@MainActor
final class StubBanknoteQualityModel: BanknoteQualityModel {
    func assess(buffer: CVPixelBuffer) async throws -> BanknoteQualityAssessment {
        BanknoteQualityAssessment(overallScore: 1.0, issues: [])
    }
}
