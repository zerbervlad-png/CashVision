import Foundation
import CoreGraphics

struct RecognizedBanknote: Identifiable, Hashable, Sendable {
    let id: UUID
    let denomination: Denomination
    let side: BanknoteSide
    let orientation: BanknoteOrientation
    let boundingBox: NormalizedRect
    let confidence: Double
    let qualityScore: Double
    let isPartial: Bool
    let definition: BanknoteDefinition?

    init(
        id: UUID = UUID(),
        denomination: Denomination,
        side: BanknoteSide = .front,
        orientation: BanknoteOrientation = .up,
        boundingBox: NormalizedRect,
        confidence: Double,
        qualityScore: Double,
        isPartial: Bool = false,
        definition: BanknoteDefinition? = nil
    ) {
        self.id = id
        self.denomination = denomination
        self.side = side
        self.orientation = orientation
        self.boundingBox = boundingBox
        self.confidence = confidence
        self.qualityScore = qualityScore
        self.isPartial = isPartial
        self.definition = definition
    }
}

enum RecognitionStatus: Equatable, Sendable {
    case idle
    case scanning
    case banknoteRecognized
    case denominationDetected
    case visualFeaturesDetected
    case additionalVerificationRequired
    case noBanknote
    case lowQuality
    case multipleBanknotes(Int)
}

struct VerificationStatus: Equatable, Sendable {
    let banknoteRecognized: Bool
    let denominationDetected: Bool
    let visualFeaturesDetected: Bool
    let requiresAdditionalCheck: Bool
    let disclaimer: String

    static let notGuaranteeDisclaimer =
        "Не является гарантией подлинности. Для окончательной проверки используйте официальный способ проверки Банка России."

    static let initial = VerificationStatus(
        banknoteRecognized: false,
        denominationDetected: false,
        visualFeaturesDetected: false,
        requiresAdditionalCheck: true,
        disclaimer: notGuaranteeDisclaimer
    )
}
