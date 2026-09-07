import Foundation

actor RateLimiter {
    private let maxRequests: Int
    private let window: TimeInterval
    private var timestamps: [Date] = []

    init(maxRequests: Int, window: TimeInterval = 60) {
        self.maxRequests = maxRequests
        self.window = window
    }

    func tryAcquire(now: Date = Date()) -> Bool {
        timestamps = timestamps.filter { now.timeIntervalSince($0) < window }
        guard timestamps.count < maxRequests else { return false }
        timestamps.append(now)
        return true
    }
}

final class APIClient: Sendable {
    let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let rateLimiter: RateLimiter
    private let maxRetries: Int
    private let timeout: TimeInterval

    init(
        baseURL: URL,
        session: URLSession = .shared,
        maxRetries: Int = 2,
        rateLimitPerMinute: Int = 60,
        timeout: TimeInterval = 15
    ) {
        self.baseURL = baseURL
        self.session = session
        self.maxRetries = maxRetries
        self.timeout = timeout
        self.rateLimiter = RateLimiter(maxRequests: rateLimitPerMinute)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder
    }

    func get<T: Decodable>(_ path: String) async throws -> T {
        try await performRequest(method: "GET", path: path, body: nil)
    }

    func post<T: Decodable, B: Encodable>(_ path: String, body: B) async throws -> T {
        let data = try encoder.encode(body)
        return try await performRequest(method: "POST", path: path, body: data)
    }

    private func performRequest<T: Decodable>(
        method: String,
        path: String,
        body: Data?
    ) async throws -> T {
        let url = baseURL.appendingPathComponent(path)
        var attempt = 0
        var lastError: Error?
        while attempt <= maxRetries {
            attempt += 1
            guard await rateLimiter.tryAcquire() else {
                AppLogger.network.notice("Rate limit exceeded for \(path)")
                throw AppError.serverError(429)
            }
            var request = URLRequest(url: url, timeoutInterval: timeout)
            request.httpMethod = method
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(UUID().uuidString, forHTTPHeaderField: "X-Request-ID")
            if let body { request.httpBody = body }

            do {
                let (data, response) = try await session.data(for: request)
                guard let http = response as? HTTPURLResponse else {
                    throw AppError.unknown
                }
                if (200..<300).contains(http.statusCode) {
                    if data.isEmpty, T.self == EmptyResponse.self {
                        return EmptyResponse() as! T
                    }
                    return try decoder.decode(T.self, from: data)
                }
                if http.statusCode == 429 || http.statusCode >= 500 {
                    let delay = pow(2.0, Double(attempt))
                    try? await Task.sleep(nanoseconds: UInt64(delay * 200_000_000))
                    lastError = AppError.serverError(http.statusCode)
                    continue
                }
                AppLogger.network.error("API \(path) failed: \(http.statusCode)")
                throw AppError.serverError(http.statusCode)
            } catch let error as AppError {
                throw error
            } catch {
                AppLogger.network.error("Network error \(path): \(error.localizedDescription)")
                lastError = AppError.networkUnavailable
                continue
            }
        }
        throw lastError ?? AppError.unknown
    }
}

struct EmptyResponse: Codable, Sendable {}
