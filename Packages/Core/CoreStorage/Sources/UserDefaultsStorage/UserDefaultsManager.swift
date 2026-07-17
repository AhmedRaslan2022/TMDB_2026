//
//  UserDefaultsManager.swift
//  TMDB
//
//  Created by Ahmed Raslan on 17/07/2026.
//

import Foundation

/// `DefaultsStorage` backed by `UserDefaults`. `UserDefaults` is documented
/// thread-safe but not annotated `Sendable` in the SDK, hence the `@unchecked`
/// conformance; tests pass a dedicated suite and wipe it afterwards.
public struct UserDefaultsManager: DefaultsStorage, @unchecked Sendable {
    private let defaults: UserDefaults

    /// - Parameter defaults: Backing store. Defaults to `.standard`; tests
    ///   pass `UserDefaults(suiteName:)` with a dedicated suite name.
    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func set(_ value: Bool, for key: DefaultsKey) {
        defaults.set(value, forKey: key.rawValue)
    }

    public func bool(for key: DefaultsKey) -> Bool {
        defaults.bool(forKey: key.rawValue)
    }

    public func set(_ value: String, for key: DefaultsKey) {
        defaults.set(value, forKey: key.rawValue)
    }

    public func string(for key: DefaultsKey) -> String? {
        defaults.string(forKey: key.rawValue)
    }

    public func removeValue(for key: DefaultsKey) {
        defaults.removeObject(forKey: key.rawValue)
    }

    public func removeAll() {
        for key in DefaultsKey.allCases {
            removeValue(for: key)
        }
    }
}
