import XCTest
@testable import CashVision

@MainActor
final class SecurityServiceTests: XCTestCase {

    func testSaveAndLoadRoundTrip() throws {
        let svc = SecurityService()
        let key = "uat.test.secret.\(UUID().uuidString)"
        defer { svc.delete(key: key) }

        try svc.save(key: key, value: "super-secret-token-123")
        let loaded = svc.load(key: key)
        XCTAssertEqual(loaded, "super-secret-token-123")
    }

    func testLoadMissingKeyReturnsNil() {
        let svc = SecurityService()
        XCTAssertNil(svc.load(key: "uat.test.does-not-exist.\(UUID().uuidString)"))
    }

    func testSaveOverwritesPreviousValue() throws {
        let svc = SecurityService()
        let key = "uat.test.overwrite.\(UUID().uuidString)"
        defer { svc.delete(key: key) }

        try svc.save(key: key, value: "first")
        try svc.save(key: key, value: "second")
        XCTAssertEqual(svc.load(key: key), "second")
    }

    func testDeleteRemovesValue() throws {
        let svc = SecurityService()
        let key = "uat.test.delete.\(UUID().uuidString)"

        try svc.save(key: key, value: "to-be-removed")
        svc.delete(key: key)
        XCTAssertNil(svc.load(key: key))
    }

    func testDeleteNonExistingDoesNotThrow() {
        let svc = SecurityService()
        svc.delete(key: "uat.test.never-existed")
        // No throw, no crash.
    }

    func testRedactShortString() {
        let svc = SecurityService()
        XCTAssertEqual(svc.redact("ab"), "••")
        XCTAssertEqual(svc.redact("abc"), "•••")
    }

    func testRedactNormalString() {
        let svc = SecurityService()
        let r = svc.redact("1234567890")
        XCTAssertTrue(r.hasPrefix("12"))
        XCTAssertTrue(r.hasSuffix("90"))
        XCTAssertTrue(r.contains("•"))
    }

    func testRedactPreservesPrefixAndSuffixByDefault() {
        let svc = SecurityService()
        let r = svc.redact("SECRET-TOKEN-XYZ", visiblePrefix: 2, visibleSuffix: 2)
        XCTAssertTrue(r.hasPrefix("SE"))
        XCTAssertTrue(r.hasSuffix("YZ"))
    }
}
