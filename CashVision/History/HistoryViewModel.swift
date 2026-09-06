import Foundation
import SwiftUI
import Observation

@MainActor
@Observable
final class HistoryViewModel {
    let repository: HistoryRepository

    init(repository: HistoryRepository) {
        self.repository = repository
    }

    var entries: [HistoryEntry] { repository.all() }

    func save(counted: [Denomination: Int], total: Int, totalCount: Int, mode: String) {
        let denominationEntries = counted.map { (denom, count) in
            DenominationEntry(currency: denom.currency, value: denom.value, count: count)
        }
        let entry = HistoryEntry(
            totalAmount: total,
            totalCount: totalCount,
            denominations: denominationEntries,
            mode: mode
        )
        repository.add(entry)
    }

    func remove(_ entry: HistoryEntry) {
        repository.remove(entry)
    }

    func clearAll() {
        repository.clear()
    }
}
