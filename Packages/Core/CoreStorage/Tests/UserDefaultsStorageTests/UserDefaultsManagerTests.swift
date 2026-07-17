//
//  UserDefaultsManagerTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 17/07/2026.
//

import Foundation
import Testing
@testable import UserDefaultsStorage

@Suite("UserDefaultsManager", .serialized)
struct UserDefaultsManagerTests {
    private static let suiteName = "com.rasslan.github.TMDB.tests.defaults"

    private let defaults: UserDefaults
    private let storage: UserDefaultsManager

    init() throws {
        let defaults = try #require(UserDefaults(suiteName: Self.suiteName))
        defaults.removePersistentDomain(forName: Self.suiteName)
        self.defaults = defaults
        storage = UserDefaultsManager(defaults: defaults)
    }

    @Test("bool roundtrip: set then read returns the stored value")
    func boolRoundtrip() {
        storage.set(true, for: .hasSeenOnboarding)
        #expect(storage.bool(for: .hasSeenOnboarding))
    }

    @Test("bool for an absent key defaults to false")
    func absentBoolIsFalse() {
        #expect(!storage.bool(for: .hasSeenOnboarding))
    }

    @Test("string roundtrip: set then read returns the stored value")
    func stringRoundtrip() {
        storage.set("value", for: .hasSeenOnboarding)
        #expect(storage.string(for: .hasSeenOnboarding) == "value")
    }

    @Test("string for an absent key is nil")
    func absentStringIsNil() {
        #expect(storage.string(for: .hasSeenOnboarding) == nil)
    }

    @Test("set overwrites an existing value")
    func setOverwrites() {
        storage.set("first", for: .hasSeenOnboarding)
        storage.set("second", for: .hasSeenOnboarding)
        #expect(storage.string(for: .hasSeenOnboarding) == "second")
    }

    @Test("removeValue deletes the value; removing an absent key does not trap")
    func removeValue() {
        storage.set("value", for: .hasSeenOnboarding)
        storage.removeValue(for: .hasSeenOnboarding)
        #expect(storage.string(for: .hasSeenOnboarding) == nil)
        storage.removeValue(for: .hasSeenOnboarding)
    }

    @Test("removeAll clears every typed key")
    func removeAll() {
        for key in DefaultsKey.allCases {
            storage.set("value", for: key)
        }
        storage.removeAll()
        for key in DefaultsKey.allCases {
            #expect(storage.string(for: key) == nil)
        }
    }
}
