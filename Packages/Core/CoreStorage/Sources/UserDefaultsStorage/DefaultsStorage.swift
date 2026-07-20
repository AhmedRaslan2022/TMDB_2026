//
//  DefaultsStorage.swift
//  TMDB
//
//  Created by Ahmed Raslan on 17/07/2026.
//

/// Typed keys for non-sensitive preferences held in `UserDefaults`. New
/// preferences get a case here — string literals never appear at call sites.
/// Credentials and tokens belong in `KeychainStorage`, never here.
public enum DefaultsKey: String, CaseIterable, Sendable {
    case hasSeenOnboarding = "tmdb.has-seen-onboarding"
    /// Appearance preference (`AppTheme` raw value).
    case appTheme = "tmdb.app-theme"
    /// Content-language preference (`AppLanguage` raw value).
    case appLanguage = "tmdb.app-language"
}

/// Key-value persistence for lightweight preferences. Implemented by
/// `UserDefaultsManager`; consumers depend on this protocol so tests can
/// substitute a mock.
public protocol DefaultsStorage: Sendable {
    /// Stores or overwrites the value for `key`.
    func set(_ value: Bool, for key: DefaultsKey)
    /// The stored value, or `false` if absent.
    func bool(for key: DefaultsKey) -> Bool
    /// Stores or overwrites the value for `key`.
    func set(_ value: String, for key: DefaultsKey)
    /// The stored value, or `nil` if absent.
    func string(for key: DefaultsKey) -> String?
    /// Removes the value for `key`. Removing an absent key is not an error.
    func removeValue(for key: DefaultsKey)
    /// Removes every value owned by this store.
    func removeAll()
}
