import Foundation
import CoreGraphics

enum SecurityCheckType: String, Codable, Sendable {
    case watermark
    case securityThread
    case microperforation
    case relief
    case holographic
    case kinematicElement
    case protectiveFibers
    case uvFeature
    case irFeature
    case latentImage
    case microtext
    case magneticInk
}

enum SecurityCheckMethod: String, Codable, Sendable {
    case onLight        // на просвет
    case onAngle        // под углом
    case onTouch        // на ощупь
    case withUV         // в УФ-излучении
    case withIR         // в ИК-излучении
    case withMagnifier  // с лупой
}

struct SecurityFeature: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    let type: SecurityCheckType
    let title: String
    let shortDescription: String
    let instructions: [String]
    let checkMethods: [SecurityCheckMethod]
    let position: NormalizedPoint
    let region: NormalizedRect?
    let visibleOnSide: BanknoteSide
    let confidenceRequired: Double

    init(
        id: UUID = UUID(),
        type: SecurityCheckType,
        title: String,
        shortDescription: String,
        instructions: [String],
        checkMethods: [SecurityCheckMethod],
        position: NormalizedPoint,
        region: NormalizedRect? = nil,
        visibleOnSide: BanknoteSide,
        confidenceRequired: Double = 0.5
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.shortDescription = shortDescription
        self.instructions = instructions
        self.checkMethods = checkMethods
        self.position = position
        self.region = region
        self.visibleOnSide = visibleOnSide
        self.confidenceRequired = confidenceRequired
    }
}
