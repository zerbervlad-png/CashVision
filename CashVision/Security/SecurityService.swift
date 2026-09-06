import Foundation
import Security

@MainActor
final class SecurityService {
    private let service = "ai.cashvision.app.secure"

    func save(key: String, value: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
        var add = query
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(add as CFDictionary, nil)
    }

    func load(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }

    func redact(_ string: String, visiblePrefix: Int = 2, visibleSuffix: Int = 2) -> String {
        guard string.count > visiblePrefix + visibleSuffix else { return String(repeating: "•", count: string.count) }
        let prefix = String(string.prefix(visiblePrefix))
        let suffix = String(string.suffix(visibleSuffix))
        let middle = String(repeating: "•", count: max(string.count - visiblePrefix - visibleSuffix, 3))
        return prefix + middle + suffix
    }
}
