import Foundation

final class LocalBanknoteDataProvider: BanknoteDataProvider, Sendable {
    private let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    func loadAllBanknotes() async throws -> [BanknoteDefinition] {
        guard let url = bundle.url(forResource: "banknotes", withExtension: "json") else {
            return LocalBanknoteDataProvider.fallbackDataset
        }
        let data = try Data(contentsOf: url)
        let decoded = try JSONDecoder().decode([BanknoteDefinition].self, from: data)
        return decoded.isEmpty ? LocalBanknoteDataProvider.fallbackDataset : decoded
    }

    func loadBanknote(denomination: Denomination) async throws -> BanknoteDefinition? {
        try await loadAllBanknotes().first {
            $0.currency == denomination.currency && $0.denominationValue == denomination.value
        }
    }

    func getSource() -> String { "Локальная база данных CashVision" }

    static let fallbackDataset: [BanknoteDefinition] = {
        RubBanknotesDataset.allBanknotes
    }()
}
