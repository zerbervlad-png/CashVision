import Foundation
import OSLog

enum AppLogger {
    static let subsystem = Bundle.main.bundleIdentifier ?? "ai.cashvision.app"

    static let camera = Logger(subsystem: subsystem, category: "camera")
    static let vision = Logger(subsystem: subsystem, category: "vision")
    static let ml = Logger(subsystem: subsystem, category: "ml")
    static let network = Logger(subsystem: subsystem, category: "network")
    static let subscription = Logger(subsystem: subsystem, category: "subscription")
    static let security = Logger(subsystem: subsystem, category: "security")
    static let database = Logger(subsystem: subsystem, category: "database")
    static let analytics = Logger(subsystem: subsystem, category: "analytics")

    static func bootstrap() {
        Logger(subsystem: subsystem, category: "app")
            .notice("CashVision started, build \(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?")")
    }
}
