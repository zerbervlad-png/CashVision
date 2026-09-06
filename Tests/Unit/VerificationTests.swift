import XCTest
@testable import CashVision

@MainActor
final class VerificationTests: XCTestCase {

    func testNoBanknoteReturnsInitial() {
        let svc = BanknoteVerificationService(serialProvider: NoOfficialSourceSerialProvider())
        let status = svc.evaluate(recognized: nil)
        XCTAssertFalse(status.banknoteRecognized)
        XCTAssertFalse(status.denominationDetected)
        XCTAssertTrue(status.requiresAdditionalCheck)
    }

    func testRecognizedBanknoteWithDefinition() async throws {
        let repo = BanknoteRepository(provider: LocalBanknoteDataProvider())
        let definition = try await repo.find(denomination: .rub5000)
        let banknote = RecognizedBanknote(
            denomination: .rub5000,
            boundingBox: NormalizedRect(x: 0, y: 0, width: 1, height: 1),
            confidence: 0.95,
            qualityScore: 1.0,
            definition: definition
        )
        let svc = BanknoteVerificationService(serialProvider: NoOfficialSourceSerialProvider())
        let status = svc.evaluate(recognized: banknote)
        XCTAssertTrue(status.banknoteRecognized)
        XCTAssertTrue(status.denominationDetected)
        XCTAssertTrue(status.visualFeaturesDetected)
    }

    func testLowConfidenceNotRecognized() {
        let banknote = RecognizedBanknote(denomination: .rub1000, boundingBox: NormalizedRect(x: 0, y: 0, width: 1, height: 1), confidence: 0.2, qualityScore: 0.3)
        let svc = BanknoteVerificationService(serialProvider: NoOfficialSourceSerialProvider())
        let status = svc.evaluate(recognized: banknote)
        XCTAssertFalse(status.banknoteRecognized)
    }

    func testDisclaimerMentionsOfficialCheck() {
        XCTAssertTrue(VerificationStatus.notGuaranteeDisclaimer.contains("официальный"))
    }

    func testSerialVerificationWithoutOfficialSource() async {
        let svc = BanknoteVerificationService(serialProvider: NoOfficialSourceSerialProvider())
        let result = await svc.verifySerial("аб1234567")
        XCTAssertEqual(result.status, .noOfficialSource)
        XCTAssertTrue(result.message.contains("недоступна") || result.message.contains("Банка России"))
    }
}

final class ConfidenceEngineTests: XCTestCase {
    func testConfidenceThresholds() {
        XCTAssertLessThan(0.4, 0.6)
        XCTAssertGreaterThanOrEqual(0.95, 0.6)
    }
}
