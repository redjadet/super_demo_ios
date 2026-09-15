//
//  AccessTokenStore.swift
//  superDemoApp
//

import Foundation
import Security

/// Persists a single access token for the networking auth demo path.
nonisolated protocol AccessTokenStore: Sendable {
    func loadAccessToken() throws -> String?
    func saveAccessToken(_ token: String) throws
    func clearAccessToken() throws
}

enum AccessTokenStoreError: Error, Equatable {
    case keychainStatus(OSStatus)
}

/// Test/demo store — not Keychain-backed.
final class InMemoryAccessTokenStore: AccessTokenStore, @unchecked Sendable {
    private let lock = NSLock()
    private var token: String?

    init(initialToken: String? = nil) {
        self.token = initialToken
    }

    func loadAccessToken() throws -> String? {
        self.lock.lock()
        defer { self.lock.unlock() }
        return self.token
    }

    func saveAccessToken(_ token: String) throws {
        self.lock.lock()
        defer { self.lock.unlock() }
        self.token = token
    }

    func clearAccessToken() throws {
        self.lock.lock()
        defer { self.lock.unlock() }
        self.token = nil
    }
}

/// App-private generic-password Keychain item for the demo access token.
/// Not a shared access group — no Keychain Sharing entitlement required.
struct KeychainAccessTokenStore: AccessTokenStore {
    private let service: String
    private let account: String

    init(
        service: String = "com.superdemoapp.token",
        account: String = "access-token"
    ) {
        self.service = service
        self.account = account
    }

    func loadAccessToken() throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: self.service,
            kSecAttrAccount as String: self.account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        switch status {
        case errSecSuccess:
            guard let data = item as? Data else { return nil }
            return String(data: data, encoding: .utf8)
        case errSecItemNotFound:
            return nil
        default:
            throw AccessTokenStoreError.keychainStatus(status)
        }
    }

    func saveAccessToken(_ token: String) throws {
        let data = Data(token.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: self.service,
            kSecAttrAccount as String: self.account,
        ]
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess {
            return
        }
        if updateStatus != errSecItemNotFound {
            throw AccessTokenStoreError.keychainStatus(updateStatus)
        }

        var addQuery = query
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw AccessTokenStoreError.keychainStatus(addStatus)
        }
    }

    func clearAccessToken() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: self.service,
            kSecAttrAccount as String: self.account,
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw AccessTokenStoreError.keychainStatus(status)
        }
    }
}
