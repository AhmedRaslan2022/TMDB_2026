//
//  KeychainManager.swift
//  TMDB
//
//  Created by Ahmed Raslan on 17/07/2026.
//

import Foundation
import Security

/// A failure reported by the Security framework, surfaced with its `OSStatus`
/// so callers can log precisely without importing `Security`.
public enum KeychainError: Error, Equatable {
    /// The stored bytes could not be decoded as UTF-8.
    case invalidData
    /// Any Security framework failure other than "not found".
    case unexpectedStatus(OSStatus)
}

/// Actor over the Security framework's generic-password keychain items.
///
/// All items are scoped to a `service` string, so a dedicated test service
/// can be wiped without touching real credentials.
public actor KeychainManager: SecureStorage {
    private let service: String

    /// - Parameter service: Keychain service namespace. Defaults to the app's
    ///   bundle-style identifier; tests pass a dedicated service name.
    public init(service: String = "com.rasslan.github.TMDB.keychain") {
        self.service = service
    }

    public func set(_ value: String, for key: SecureStorageKey) async throws {
        let data = Data(value.utf8)
        var query = baseQuery(for: key)

        let attributes: [CFString: Any] = [kSecValueData: data]
        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        switch updateStatus {
        case errSecSuccess:
            return
        case errSecItemNotFound:
            query[kSecValueData] = data
            query[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            let addStatus = SecItemAdd(query as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw KeychainError.unexpectedStatus(addStatus)
            }
        default:
            throw KeychainError.unexpectedStatus(updateStatus)
        }
    }

    public func string(for key: SecureStorageKey) async throws -> String? {
        var query = baseQuery(for: key)
        query[kSecReturnData] = true
        query[kSecMatchLimit] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            guard let data = result as? Data, let string = String(data: data, encoding: .utf8) else {
                throw KeychainError.invalidData
            }
            return string
        case errSecItemNotFound:
            return nil
        default:
            throw KeychainError.unexpectedStatus(status)
        }
    }

    public func removeValue(for key: SecureStorageKey) async throws {
        let status = SecItemDelete(baseQuery(for: key) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    public func removeAll() async throws {
        // Per-key deletion: a service-wide SecItemDelete only removes the
        // first match on macOS's file-based keychain, and the typed key set
        // is closed anyway.
        for key in SecureStorageKey.allCases {
            try await removeValue(for: key)
        }
    }

    private func baseQuery(for key: SecureStorageKey) -> [CFString: Any] {
        [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key.rawValue,
        ]
    }
}
