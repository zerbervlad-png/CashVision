import Foundation

protocol BanknoteSerialVerificationProvider: Sendable {
    func checkSerialNumber(_ serial: String) async throws -> SerialVerificationResult
    func getSource() -> String
    func getTimestamp() -> Date?
    var isAvailable: Bool { get }
}

struct SerialVerificationResult: Sendable, Hashable {
    enum Status: String, Sendable {
        case noOfficialSource
        case notFoundInLists
        case potentiallyInvalid
        case invalid
        case unknown
    }
    let serial: String
    let status: Status
    let source: String
    let timestamp: Date
    let message: String
}

final class CompositeSerialVerificationProvider: BanknoteSerialVerificationProvider {
    private let providers: [BanknoteSerialVerificationProvider]

    init(providers: [BanknoteSerialVerificationProvider] = []) {
        if providers.isEmpty {
            self.providers = [NoOfficialSourceSerialProvider()]
        } else {
            self.providers = providers
        }
    }

    func checkSerialNumber(_ serial: String) async throws -> SerialVerificationResult {
        guard !serial.isEmpty else {
            throw AppError.unknown
        }
        for provider in providers where provider.isAvailable {
            return try await provider.checkSerialNumber(serial)
        }
        return try await NoOfficialSourceSerialProvider().checkSerialNumber(serial)
    }

    func getSource() -> String { providers.first?.getSource() ?? "Нет официального источника" }
    func getTimestamp() -> Date? { providers.first?.getTimestamp() }
    var isAvailable: Bool { providers.contains { $0.isAvailable } }
}

final class NoOfficialSourceSerialProvider: BanknoteSerialVerificationProvider {
    var isAvailable: Bool { false }
    func checkSerialNumber(_ serial: String) async throws -> SerialVerificationResult {
        SerialVerificationResult(
            serial: serial,
            status: .noOfficialSource,
            source: "Официальный публичный API Банка России для проверки серийных номеров банкнот отсутствует",
            timestamp: Date(),
            message: "Проверка по внешней базе недоступна. Используйте официальный способ проверки Банка России."
        )
    }
    func getSource() -> String { "Нет официального источника" }
    func getTimestamp() -> Date? { nil }
}
