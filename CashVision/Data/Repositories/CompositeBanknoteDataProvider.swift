import Foundation

final class CompositeBanknoteDataProvider: BanknoteDataProvider {
    private let local: BanknoteDataProvider
    private let remote: BanknoteDataProvider

    init(local: BanknoteDataProvider, remote: BanknoteDataProvider) {
        self.local = local
        self.remote = remote
    }

    func loadAllBanknotes() async throws -> [BanknoteDefinition] {
        do {
            return try await remote.loadAllBanknotes()
        } catch {
            AppLogger.database.notice("Falling back to local dataset: \(error.localizedDescription)")
            return try await local.loadAllBanknotes()
        }
    }

    func loadBanknote(denomination: Denomination) async throws -> BanknoteDefinition? {
        do {
            if let remote = try await remote.loadBanknote(denomination: denomination) {
                return remote
            }
            return try await local.loadBanknote(denomination: denomination)
        } catch {
            return try await local.loadBanknote(denomination: denomination)
        }
    }

    func getSource() -> String { "Composite (remote + local fallback)" }
}
