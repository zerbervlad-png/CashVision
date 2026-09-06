import XCTest
@testable import CashVision

@MainActor
final class BanknoteTrackerTests: XCTestCase {
    func testNewBanknoteIsCounted() {
        let tracker = BanknoteTracker()
        let b = RecognizedBanknote(denomination: .rub5000, boundingBox: NormalizedRect(x: 0.1, y: 0.1, width: 0.8, height: 0.6), confidence: 0.95, qualityScore: 1)
        XCTAssertEqual(tracker.track(b), .newCounted)
    }

    func testSameBanknoteSecondTimeIsDuplicate() {
        let tracker = BanknoteTracker()
        let b = RecognizedBanknote(denomination: .rub5000, boundingBox: NormalizedRect(x: 0.1, y: 0.1, width: 0.8, height: 0.6), confidence: 0.95, qualityScore: 1)
        _ = tracker.track(b)
        XCTAssertEqual(tracker.track(b), .alreadyCounted)
    }

    func testDifferentPositionsAreNew() {
        let tracker = BanknoteTracker()
        let b1 = RecognizedBanknote(denomination: .rub5000, boundingBox: NormalizedRect(x: 0.0, y: 0.0, width: 0.4, height: 0.4), confidence: 0.9, qualityScore: 1)
        let b2 = RecognizedBanknote(denomination: .rub5000, boundingBox: NormalizedRect(x: 0.6, y: 0.6, width: 0.4, height: 0.4), confidence: 0.9, qualityScore: 1)
        XCTAssertEqual(tracker.track(b1), .newCounted)
        XCTAssertEqual(tracker.track(b2), .newCounted)
    }

    func testStaleBanknoteIsPurged() {
        let tracker = BanknoteTracker()
        let b1 = RecognizedBanknote(denomination: .rub5000, boundingBox: NormalizedRect(x: 0.0, y: 0.0, width: 0.4, height: 0.4), confidence: 0.9, qualityScore: 1)
        _ = tracker.track(b1, now: Date().addingTimeInterval(-10))
        XCTAssertEqual(tracker.track(b1), .newCounted)
    }

    func testDifferentDenominationIsSeparateObject() {
        let tracker = BanknoteTracker()
        let b1 = RecognizedBanknote(denomination: .rub5000, boundingBox: NormalizedRect(x: 0.0, y: 0.0, width: 0.4, height: 0.4), confidence: 0.9, qualityScore: 1)
        let b2 = RecognizedBanknote(denomination: .rub1000, boundingBox: NormalizedRect(x: 0.05, y: 0.05, width: 0.4, height: 0.4), confidence: 0.9, qualityScore: 1)
        XCTAssertEqual(tracker.track(b1), .newCounted)
        XCTAssertEqual(tracker.track(b2), .newCounted)
        XCTAssertEqual(tracker.activeCount, 2)
    }

    func testResetClearsState() {
        let tracker = BanknoteTracker()
        let b1 = RecognizedBanknote(denomination: .rub5000, boundingBox: NormalizedRect(x: 0.0, y: 0.0, width: 0.4, height: 0.4), confidence: 0.9, qualityScore: 1)
        _ = tracker.track(b1)
        tracker.reset()
        XCTAssertEqual(tracker.activeCount, 0)
        XCTAssertEqual(tracker.track(b1), .newCounted)
    }
}
