import Foundation
import SwiftData
import Observation

@Model
final class HistoryEntry {
    @Attribute(.unique) var id: UUID
    var date: Date
    var totalAmount: Int
    var totalCount: Int
    var denominationsJSON: String
    var mode: String

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        totalAmount: Int,
        totalCount: Int,
        denominations: [DenominationEntry],
        mode: String
    ) {
        self.id = id
        self.date = date
        self.totalAmount = totalAmount
        self.totalCount = totalCount
        self.mode = mode
        if let data = try? JSONEncoder().encode(denominations),
           let str = String(data: data, encoding: .utf8) {
            self.denominationsJSON = str
        } else {
            self.denominationsJSON = "[]"
        }
    }

    var denominations: [DenominationEntry] {
        guard let data = denominationsJSON.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([DenominationEntry].self, from: data)) ?? []
    }
}

struct DenominationEntry: Codable, Hashable, Identifiable {
    let id: UUID
    let currency: Currency
    let value: Int
    let count: Int

    init(id: UUID = UUID(), currency: Currency, value: Int, count: Int) {
        self.id = id
        self.currency = currency
        self.value = value
        self.count = count
    }

    var formatted: String {
        "\(value) \(currency.symbol) × \(count)"
    }
}

@MainActor
final class HistoryRepository {
    private var entries: [HistoryEntry] = []

    func all() -> [HistoryEntry] { entries.sorted { $0.date > $1.date } }

    func add(_ entry: HistoryEntry) {
        entries.append(entry)
        AppLogger.database.info("History entry added: \(entry.totalAmount) rubles")
    }

    func remove(_ entry: HistoryEntry) {
        entries.removeAll { $0.id == entry.id }
    }

    func clear() {
        entries.removeAll()
    }
}
