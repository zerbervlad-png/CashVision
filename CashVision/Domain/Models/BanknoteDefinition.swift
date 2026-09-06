import Foundation

struct BanknoteDefinition: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    let currency: Currency
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

    var denomination: Denomination {
        Denomination(currency: currency, value: denominationValue)
    }

    var formattedValue: String { denomination.formatted }

    init(
        id: UUID = UUID(),
        currency: Currency,
        denominationValue: Int,
        issueYear: Int,
        series: String,
        frontImageName: String,
        backImageName: String,
        securityFeatures: [SecurityFeature],
        officialDescription: String,
        officialSourceURL: URL? = nil,
        supportedChecks: [SecurityCheckType] = [],
        accessibilityDescription: String = ""
    ) {
        self.id = id
        self.currency = currency
        self.denominationValue = denominationValue
        self.issueYear = issueYear
        self.series = series
        self.frontImageName = frontImageName
        self.backImageName = backImageName
        self.securityFeatures = securityFeatures
        self.officialDescription = officialDescription
        self.officialSourceURL = officialSourceURL
        self.supportedChecks = supportedChecks
        self.accessibilityDescription = accessibilityDescription
    }
}
