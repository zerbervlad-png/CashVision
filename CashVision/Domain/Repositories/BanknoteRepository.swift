import Foundation

protocol BanknoteDataProvider: Sendable {
    func loadAllBanknotes() async throws -> [BanknoteDefinition]
    func loadBanknote(denomination: Denomination) async throws -> BanknoteDefinition?
    func getSource() -> String
}

protocol BanknoteRepositoryProtocol: Sendable {
    func getAll() async throws -> [BanknoteDefinition]
    func find(denomination: Denomination) async throws -> BanknoteDefinition?
}

final class BanknoteRepository: BanknoteRepositoryProtocol, @unchecked Sendable {
    private let provider: BanknoteDataProvider
    private let cache = NSCache<NSString, AnyObject>()

    init(provider: BanknoteDataProvider) {
        self.provider = provider
    }

    func getAll() async throws -> [BanknoteDefinition] {
        if let cached = cache.object(forKey: "all") as? Box<[BanknoteDefinition]> {
            return cached.value
        }
        let banknotes = try await provider.loadAllBanknotes()
        cache.setObject(Box(banknotes), forKey: "all")
        return banknotes
    }

    func find(denomination: Denomination) async throws -> BanknoteDefinition? {
        let key = "\(denomination.currency.rawValue)-\(denomination.value)" as NSString
        if let cached = cache.object(forKey: key) as? Box<BanknoteDefinition?> {
            return cached.value
        }
        let banknote = try await provider.loadBanknote(denomination: denomination)
        cache.setObject(Box(banknote), forKey: key)
        return banknote
    }
}

final class Box<T>: AnyObject {
    let value: T
    init(_ value: T) { self.value = value }
}
