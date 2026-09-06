import XCTest
@testable import CashVision

final class BanknoteRepositoryTests: XCTestCase {

    func testLocalProviderLoadsAllBanknotes() async throws {
        let provider = LocalBanknoteDataProvider()
        let repo = BanknoteRepository(provider: provider)
        let all = try await repo.getAll()
        XCTAssertFalse(all.isEmpty)
        XCTAssertTrue(all.contains { $0.denominationValue == 5000 })
    }

    func testFind5000() async throws {
        let provider = LocalBanknoteDataProvider()
        let repo = BanknoteRepository(provider: provider)
        let banknote = try await repo.find(denomination: .rub5000)
        XCTAssertEqual(banknote?.denominationValue, 5000)
        XCTAssertFalse(banknote?.securityFeatures.isEmpty ?? true)
    }

    func testFindUnknownReturnsNil() async throws {
        let provider = LocalBanknoteDataProvider()
        let repo = BanknoteRepository(provider: provider)
        let banknote = try await repo.find(denomination: Denomination(currency: .rub, value: 99999))
        XCTAssertNil(banknote)
    }

    func testCachedBanknoteDefinitionMatches() async throws {
        let provider = LocalBanknoteDataProvider()
        let repo = BanknoteRepository(provider: provider)
        let first = try await repo.find(denomination: .rub1000)
        let second = try await repo.find(denomination: .rub1000)
        XCTAssertEqual(first?.id, second?.id)
    }
}
