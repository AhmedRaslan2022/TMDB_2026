// By Ahmed Raslan ®

import Foundation
import Testing
@testable import CoreStorage

/// Runs against the real keychain under a dedicated test service; every test
/// wipes that service afterwards so nothing leaks between runs or into the
/// app's real credentials.
@Suite(.serialized)
struct KeychainManagerTests {
    private let manager = KeychainManager(service: "com.rasslan.github.TMDB.keychain.tests")

    private func cleanUp() async throws {
        try await manager.removeAll()
    }

    @Test func storeAndReadRoundtrip() async throws {
        try await manager.set("session-123", for: .sessionID)

        let value = try await manager.string(for: .sessionID)

        #expect(value == "session-123")
        try await cleanUp()
    }

    @Test func overwritesExistingValue() async throws {
        try await manager.set("first", for: .sessionID)
        try await manager.set("second", for: .sessionID)

        let value = try await manager.string(for: .sessionID)

        #expect(value == "second")
        try await cleanUp()
    }

    @Test func missingKeyReturnsNil() async throws {
        let value = try await manager.string(for: .accountID)

        #expect(value == nil)
        try await cleanUp()
    }

    @Test func removeValueDeletesOnlyThatKey() async throws {
        try await manager.set("session", for: .sessionID)
        try await manager.set("42", for: .accountID)

        try await manager.removeValue(for: .sessionID)

        #expect(try await manager.string(for: .sessionID) == nil)
        #expect(try await manager.string(for: .accountID) == "42")
        try await cleanUp()
    }

    @Test func removingAbsentKeyDoesNotThrow() async throws {
        try await manager.removeValue(for: .guestSessionID)
        try await cleanUp()
    }

    @Test func removeAllClearsEveryKey() async throws {
        for key in SecureStorageKey.allCases {
            try await manager.set("value-\(key.rawValue)", for: key)
        }

        try await manager.removeAll()

        for key in SecureStorageKey.allCases {
            #expect(try await manager.string(for: key) == nil)
        }
    }

    @Test func servicesAreIsolated() async throws {
        let other = KeychainManager(service: "com.rasslan.github.TMDB.keychain.tests.other")
        try await manager.set("mine", for: .sessionID)

        let foreign = try await other.string(for: .sessionID)

        #expect(foreign == nil)
        try await other.removeAll()
        try await cleanUp()
    }
}
