//
//  AppFavoritesAccountProviderTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

import FeatureFavorites
import KeychainStorage
import Testing
@testable import TMDB

/// The gate that keeps favorites remote-sync inert until Profile (5.1) stores
/// the account ID: no account ID → nil (guest / not-yet-resolved); both keys
/// present → a real account.
@Suite("AppFavoritesAccountProvider")
struct AppFavoritesAccountProviderTests {
    /// In-memory `SecureStorage` — no real keychain (unavailable to unhosted
    /// runners anyway).
    actor InMemorySecureStorage: SecureStorage {
        private var values: [SecureStorageKey: String] = [:]

        func set(_ value: String, for key: SecureStorageKey) async throws {
            values[key] = value
        }

        func string(for key: SecureStorageKey) async throws -> String? {
            values[key]
        }

        func removeValue(for key: SecureStorageKey) async throws {
            values[key] = nil
        }

        func removeAll() async throws {
            values.removeAll()
        }
    }

    @Test("nil when no account id is stored (guest / pre-Profile)")
    func nilWithoutAccountID() async throws {
        let storage = InMemorySecureStorage()
        try await storage.set("session-1", for: .sessionID)
        let provider = AppFavoritesAccountProvider(secureStorage: storage)

        #expect(await provider.currentAccount() == nil)
    }

    @Test("nil when the account id is non-numeric")
    func nilWhenAccountIDMalformed() async throws {
        let storage = InMemorySecureStorage()
        try await storage.set("not-a-number", for: .accountID)
        try await storage.set("session-1", for: .sessionID)
        let provider = AppFavoritesAccountProvider(secureStorage: storage)

        #expect(await provider.currentAccount() == nil)
    }

    @Test("nil when the account id is present but the session id is missing")
    func nilWithoutSession() async throws {
        let storage = InMemorySecureStorage()
        try await storage.set("42", for: .accountID)
        let provider = AppFavoritesAccountProvider(secureStorage: storage)

        #expect(await provider.currentAccount() == nil)
    }

    @Test("resolves an account when both credentials are present")
    func resolvesAccount() async throws {
        let storage = InMemorySecureStorage()
        try await storage.set("42", for: .accountID)
        try await storage.set("session-1", for: .sessionID)
        let provider = AppFavoritesAccountProvider(secureStorage: storage)

        let account = await provider.currentAccount()
        #expect(account?.accountID == 42)
        #expect(account?.sessionID == "session-1")
    }
}
