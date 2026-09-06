import Foundation
import Security

enum SecurityError: Error {
    case saveFailed(OSStatus)
    case loadFailed(OSStatus)
}

@MainActor
final class SecurityService {
    private let service = "ai.cashvision.app.secure"

    func save(key: String, value: String) throws {
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
        let status = SecItemAdd(add as CFDictionary, nil)
        guard status == errSecSuccess else {
            AppLogger.security.error("Keychain save failed for key=\(key), status=\(status)")
            throw SecurityError.saveFailed(status)
        }
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
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let data = item as? Data else {
            if status != errSecItemNotFound {
                AppLogger.security.error("Keychain load failed for key=\(key), status=\(status)")
            }
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            AppLogger.security.error("Keychain delete failed for key=\(key), status=\(status)")
        }
    }

    func redact(_ string: String, visiblePrefix: Int = 2, visibleSuffix: Int = 2) -> String {
        guard string.count > visiblePrefix + visibleSuffix else { return String(repeating: "•", count: string.count) }
        let prefix = String(string.prefix(visiblePrefix))
        let suffix = String(string.suffix(visibleSuffix))
        let middle = String(repeating: "•", count: max(string.count - visiblePrefix - visibleSuffix, 3))
        return prefix + middle + suffix
    }
}
