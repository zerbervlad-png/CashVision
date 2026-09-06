import Foundation
import CoreGraphics

enum Currency: String, Codable, CaseIterable, Sendable {
    case rub = "RUB"
    case usd = "USD"
    case eur = "EUR"

    var symbol: String {
        switch self {
        case .rub: return "₽"
        case .usd: return "$"
        case .eur: return "€"
        }
    }
}

enum BanknoteSide: String, Codable, Sendable {
    case front
    case back
}

enum BanknoteOrientation: String, Codable, Sendable {
    case up
    case down
    case left
    case right
}

struct Denomination: Hashable, Codable, Sendable, Identifiable {
    let currency: Currency
    let value: Int

    var id: String { "\(currency.rawValue)-\(value)" }

    var formatted: String {
        "\(value) \(currency.symbol)"
    }

    var displayValue: String { formatted }

    static let rub5000 = Denomination(currency: .rub, value: 5000)
    static let rub2000 = Denomination(currency: .rub, value: 2000)
    static let rub1000 = Denomination(currency: .rub, value: 1000)
    static let rub500  = Denomination(currency: .rub, value: 500)
    static let rub200  = Denomination(currency: .rub, value: 200)
    static let rub100  = Denomination(currency: .rub, value: 100)
    static let rub50   = Denomination(currency: .rub, value: 50)
    static let rub10   = Denomination(currency: .rub, value: 10)
}

struct NormalizedPoint: Hashable, Codable, Sendable {
    var x: CGFloat
    var y: CGFloat
    init(x: CGFloat, y: CGFloat) { self.x = x; self.y = y }
}

struct NormalizedRect: Hashable, Codable, Sendable {
    var x: CGFloat
    var y: CGFloat
    var width: CGFloat
    var height: CGFloat
    init(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) {
        self.x = x; self.y = y; self.width = width; self.height = height
    }
}
