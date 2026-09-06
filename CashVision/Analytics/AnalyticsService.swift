import Foundation

protocol AnalyticsClient: Sendable {
    func track(_ event: AnalyticsEvent)
}

struct AnalyticsEvent: Sendable {
    enum Name: String, Sendable {
        case appOpen = "app_open"
        case cameraStarted = "camera_started"
        case banknoteDetected = "banknote_detected"
        case denominationDetected = "denomination_detected"
        case countingStarted = "counting_started"
        case countingCompleted = "counting_completed"
        case paywallOpened = "paywall_opened"
        case subscriptionStarted = "subscription_started"
        case errorOccurred = "error_occurred"
    }
    let name: Name
    let properties: [String: String]
    let timestamp: Date

    init(name: Name, properties: [String: String] = [:], timestamp: Date = Date()) {
        self.name = name
        self.properties = properties
        self.timestamp = timestamp
    }
}

final class AnalyticsService: AnalyticsClient {
    private let userDefaults = UserDefaults.standard
    private let enabledKey = "allowAnalytics"

    func track(_ event: AnalyticsEvent) {
        guard userDefaults.object(forKey: enabledKey) as? Bool ?? true else { return }
        AppLogger.analytics.info("event=\(event.name.rawValue) props=\(event.properties)")
    }
}
