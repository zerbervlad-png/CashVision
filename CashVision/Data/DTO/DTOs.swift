import Foundation

struct BanknoteDTO: Codable, Sendable {
    let id: UUID
    let currency: String
    let denominationValue: Int
    let issueYear: Int
    let series: String
    let frontImageName: String
    let backImageName: String
    let securityFeatures: [SecurityFeature]
    let officialDescription: String
    let officialSourceURL: URL?
    let supportedChecks: [SecurityCheckType]
    let accessibilityDescription: String

    static func toDomain(_ dto: BanknoteDTO) -> BanknoteDefinition {
        BanknoteDefinition(
            id: dto.id,
            currency: Currency(rawValue: dto.currency) ?? .rub,
            denominationValue: dto.denominationValue,
            issueYear: dto.issueYear,
            series: dto.series,
            frontImageName: dto.frontImageName,
            backImageName: dto.backImageName,
            securityFeatures: dto.securityFeatures,
            officialDescription: dto.officialDescription,
            officialSourceURL: dto.officialSourceURL,
            supportedChecks: dto.supportedChecks,
            accessibilityDescription: dto.accessibilityDescription
        )
    }
}

struct HealthDTO: Codable, Sendable {
    let status: String
    let version: String
    let timestamp: Date
}

struct ModelVersionDTO: Codable, Sendable {
    let name: String
    let version: String
    let miniOSVersion: String
    let downloadURL: URL?
    let checksum: String?
}

struct SerialVerificationDTO: Codable, Sendable {
    let serial: String
    let status: String
    let source: String
    let timestamp: Date
    let message: String

    func toDomain() -> SerialVerificationResult {
        let statusEnum = SerialVerificationResult.Status(rawValue: status) ?? .unknown
        return SerialVerificationResult(
            serial: serial,
            status: statusEnum,
            source: source,
            timestamp: timestamp,
            message: message
        )
    }
}

struct APIErrorDTO: Codable, Sendable {
    let error: String
    let code: Int
    let requestId: String
}

struct FeatureFlagsDTO: Codable, Sendable {
    let countingEnabled: Bool
    let maxFreeScansPerDay: Int
    let serialVerificationAvailable: Bool
    let remoteModelEnabled: Bool
}
