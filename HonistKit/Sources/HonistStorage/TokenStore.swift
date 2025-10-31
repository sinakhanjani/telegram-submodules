import Foundation
import Security

public protocol TokenStoreType: AnyObject {
    var accessToken: String? { get set }
    var refreshToken: String? { get set }
    func clearAll()
}

/// Keychain-backed store with UserDefaults fallback.
public final class TokenStore: TokenStoreType {
    private let service = "HonistKit.Auth"
    private let accountAccess = "access"
    private let accountRefresh = "refresh"

    private let fallback = DefaultsStore()

    public init() {}

    public var accessToken: String? {
        get { readKeychain(account: accountAccess) ?? fallback.get("auth.accessToken") }
        set {
            if let v = newValue {
                _ = saveKeychain(account: accountAccess, value: v)
                fallback.set(v, forKey: "auth.accessToken")
            } else {
                deleteKeychain(account: accountAccess)
            }
        }
    }

    public var refreshToken: String? {
        get { readKeychain(account: accountRefresh) ?? fallback.get("auth.refreshToken") }
        set {
            if let v = newValue {
                _ = saveKeychain(account: accountRefresh, value: v)
                fallback.set(v, forKey: "auth.refreshToken")
            } else {
                deleteKeychain(account: accountRefresh)
            }
        }
    }

    public func clearAll() {
        deleteKeychain(account: accountAccess)
        deleteKeychain(account: accountRefresh)
    }

    // MARK: - Keychain helpers

    private func saveKeychain(account: String, value: String) -> Bool {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String           : kSecClassGenericPassword,
            kSecAttrService as String     : service,
            kSecAttrAccount as String     : account,
            kSecValueData as String       : data
        ]
        SecItemDelete(query as CFDictionary) // replace if exists
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    private func readKeychain(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String           : kSecClassGenericPassword,
            kSecAttrService as String     : service,
            kSecAttrAccount as String     : account,
            kSecReturnData as String      : kCFBooleanTrue!,
            kSecMatchLimit as String      : kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func deleteKeychain(account: String) {
        let query: [String: Any] = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrService as String : service,
            kSecAttrAccount as String : account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
