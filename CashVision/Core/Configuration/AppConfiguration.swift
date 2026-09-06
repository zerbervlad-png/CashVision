import Foundation

struct AppConfiguration {
    let apiBaseURL: URL
    let productIDs: Set<String>
    let inferenceFramesPerSecond: Double
    let idleInferenceFramesPerSecond: Double
    let requestTimeout: TimeInterval
    let maxRequestRetries: Int
    let rateLimitRequestsPerMinute: Int
    let isDebugMode: Bool

    static let defaultProductIDs: Set<String> = [
        "cashvision.premium.monthly",
        "cashvision.premium.yearly"
    ]

    static func load() -> AppConfiguration {
        let info = ProcessInfo.processInfo
        let baseURLString = info.environment["CASHVISION_API_BASE_URL"]
            ?? "https://api.cashvision.ai"
        let isDebug = info.environment["CASHVISION_DEBUG"] != nil
            || _isDebugAssertConfiguration()
        return AppConfiguration(
            apiBaseURL: URL(string: baseURLString) ?? URL(string: "https://api.cashvision.ai")!,
            productIDs: defaultProductIDs,
            inferenceFramesPerSecond: 12,
            idleInferenceFramesPerSecond: 3,
            requestTimeout: 15,
            maxRequestRetries: 2,
            rateLimitRequestsPerMinute: 60,
            isDebugMode: isDebug
        )
    }
}
