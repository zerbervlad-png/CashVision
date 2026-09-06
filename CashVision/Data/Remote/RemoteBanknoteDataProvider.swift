import Foundation

final class RemoteBanknoteDataProvider: BanknoteDataProvider {
    private let apiClient: APIClient
    private let endpoint = "/api/v1/banknotes"

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func loadAllBanknotes() async throws -> [BanknoteDefinition] {
        let dtos: [BanknoteDTO] = try await apiClient.get(endpoint)
        return dtos.map(BanknoteDTO.toDomain)
    }

    func loadBanknote(denomination: Denomination) async throws -> BanknoteDefinition? {
        let path = "\(endpoint)/\(denomination.currency.rawValue)-\(denomination.value)"
        let dto: BanknoteDTO = try await apiClient.get(path)
        return BanknoteDTO.toDomain(dto)
    }

    func getSource() -> String { "Remote API" }
}
