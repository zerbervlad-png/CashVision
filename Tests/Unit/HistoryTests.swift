import XCTest
@testable import CashVision

@MainActor
final class HistoryTests: XCTestCase {

    func testSaveAndRetrieveEntry() {
        let repo = HistoryRepository()
        let vm = HistoryViewModel(repository: repo)
        vm.save(counted: [.rub5000: 5, .rub1000: 3], total: 28000, totalCount: 8, mode: "count")
        XCTAssertEqual(vm.entries.count, 1)
        XCTAssertEqual(vm.entries.first?.totalAmount, 28000)
        XCTAssertEqual(vm.entries.first?.totalCount, 8)
    }

    func testRemoveEntry() {
        let repo = HistoryRepository()
        let vm = HistoryViewModel(repository: repo)
        vm.save(counted: [.rub100: 1], total: 100, totalCount: 1, mode: "count")
        let entry = vm.entries.first!
        vm.remove(entry)
        XCTAssertTrue(vm.entries.isEmpty)
    }

    func testClearAll() {
        let repo = HistoryRepository()
        let vm = HistoryViewModel(repository: repo)
        vm.save(counted: [.rub100: 1], total: 100, totalCount: 1, mode: "count")
        vm.save(counted: [.rub500: 2], total: 1000, totalCount: 2, mode: "count")
        vm.clearAll()
        XCTAssertTrue(vm.entries.isEmpty)
    }

    func testEntriesSortedByDateDesc() async throws {
        let repo = HistoryRepository()
        let vm = HistoryViewModel(repository: repo)
        vm.save(counted: [.rub100: 1], total: 100, totalCount: 1, mode: "count")
        try await Task.sleep(nanoseconds: 50_000_000)
        vm.save(counted: [.rub5000: 1], total: 5000, totalCount: 1, mode: "count")
        XCTAssertEqual(vm.entries.first?.totalAmount, 5000)
    }

    func testDenominationEntryFormatted() {
        let entry = DenominationEntry(currency: .rub, value: 5000, count: 3)
        XCTAssertEqual(entry.formatted, "5000 ₽ × 3")
    }
}

final class APIClientTests: XCTestCase {
    func testRateLimiterAllowsUntilLimit() async {
        let limiter = RateLimiter(maxRequests: 3, window: 60)
        var acquired = 0
        for _ in 0..<5 {
            if await limiter.tryAcquire() { acquired += 1 }
        }
        XCTAssertEqual(acquired, 3)
    }

    func testAPIClientURLComposed() {
        let client = APIClient(baseURL: URL(string: "https://api.example.com")!)
        XCTAssertEqual(client.baseURL.absoluteString, "https://api.example.com")
    }
}
