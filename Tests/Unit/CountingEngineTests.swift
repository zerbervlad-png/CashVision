import XCTest
@testable import CashVision

final class CountingEngineTests: XCTestCase {
    @MainActor
    func testEmptyResultDoesNotChangeCount() {
        let svc = CountingService(recognition: BanknoteRecognitionService())
        svc.startCounting()
        svc.update(with: RecognitionResult(banknotes: [], quality: BanknoteQualityAssessment(overallScore: 1, issues: []), timestamp: Date()))
        XCTAssertEqual(svc.totalCount, 0)
        XCTAssertEqual(svc.totalAmount, 0)
    }

    @MainActor
    func testSingleBanknoteIsCountedOnce() {
        let svc = CountingService(recognition: BanknoteRecognitionService())
        svc.startCounting()
        let banknote = RecognizedBanknote(
            denomination: .rub5000,
            boundingBox: NormalizedRect(x: 0.1, y: 0.1, width: 0.8, height: 0.6),
            confidence: 0.9,
            qualityScore: 1.0
        )
        let result = RecognitionResult(banknotes: [banknote], quality: BanknoteQualityAssessment(overallScore: 1, issues: []), timestamp: Date())
        svc.update(with: result)
        XCTAssertEqual(svc.totalCount, 1)
        XCTAssertEqual(svc.totalAmount, 5000)
    }

    @MainActor
    func testDuplicateNotCountedTwice() {
        let svc = CountingService(recognition: BanknoteRecognitionService())
        svc.startCounting()
        let banknote = RecognizedBanknote(
            denomination: .rub1000,
            boundingBox: NormalizedRect(x: 0.1, y: 0.1, width: 0.8, height: 0.6),
            confidence: 0.9,
            qualityScore: 1.0
        )
        let result = RecognitionResult(banknotes: [banknote], quality: BanknoteQualityAssessment(overallScore: 1, issues: []), timestamp: Date())
        svc.update(with: result)
        svc.update(with: result)
        XCTAssertEqual(svc.totalCount, 1)
        XCTAssertEqual(svc.totalAmount, 1000)
    }

    @MainActor
    func testMultipleDenominationsSummed() {
        let svc = CountingService(recognition: BanknoteRecognitionService())
        svc.startCounting()
        let b1 = RecognizedBanknote(denomination: .rub5000, boundingBox: NormalizedRect(x: 0, y: 0, width: 0.4, height: 0.4), confidence: 0.9, qualityScore: 1)
        let b2 = RecognizedBanknote(denomination: .rub1000, boundingBox: NormalizedRect(x: 0.6, y: 0.6, width: 0.4, height: 0.4), confidence: 0.9, qualityScore: 1)
        let result = RecognitionResult(banknotes: [b1, b2], quality: BanknoteQualityAssessment(overallScore: 1, issues: []), timestamp: Date())
        svc.update(with: result)
        XCTAssertEqual(svc.totalCount, 2)
        XCTAssertEqual(svc.totalAmount, 6000)
    }

    @MainActor
    func testManualIncrement() {
        let svc = CountingService(recognition: BanknoteRecognitionService())
        svc.startCounting()
        svc.increment(denomination: .rub500, by: 3)
        XCTAssertEqual(svc.counted[.rub500], 3)
        XCTAssertEqual(svc.totalAmount, 1500)
    }

    @MainActor
    func testManualDecrement() {
        let svc = CountingService(recognition: BanknoteRecognitionService())
        svc.startCounting()
        svc.increment(denomination: .rub500, by: 5)
        svc.increment(denomination: .rub500, by: -2)
        XCTAssertEqual(svc.counted[.rub500], 3)
        XCTAssertEqual(svc.totalAmount, 1500)
    }

    @MainActor
    func testClearResetsState() {
        let svc = CountingService(recognition: BanknoteRecognitionService())
        svc.startCounting()
        svc.increment(denomination: .rub100, by: 4)
        svc.clear()
        XCTAssertEqual(svc.totalCount, 0)
        XCTAssertEqual(svc.totalAmount, 0)
        XCTAssertTrue(svc.counted.isEmpty)
    }
}
