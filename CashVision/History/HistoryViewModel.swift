import Foundation
import SwiftUI
import Observation

@MainActor
@Observable
final class HistoryViewModel {
    let repository: HistoryRepository
    private(set) var entries: [HistoryEntry]

    init(repository: HistoryRepository) {
        self.repository = repository
        self.entries = repository.all()
    }

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
        entries = repository.all()
    }

    func remove(_ entry: HistoryEntry) {
        repository.remove(entry)
        entries = repository.all()
    }

    func clearAll() {
        repository.clear()
        entries = repository.all()
    }
}
