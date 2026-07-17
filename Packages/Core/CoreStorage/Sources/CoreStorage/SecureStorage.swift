// By Ahmed Raslan ®

/// Typed keys for values held in secure storage. New credentials get a case
/// here — string literals never appear at call sites.
public enum SecureStorageKey: String, CaseIterable, Sendable {
    case sessionID = "tmdb.session-id"
    case guestSessionID = "tmdb.guest-session-id"
    case accountID = "tmdb.account-id"
}

/// Secure persistence for credentials. Implemented by `KeychainManager`;
/// consumers depend on this protocol so tests can substitute a mock.
public protocol SecureStorage: Sendable {
    /// Stores or overwrites the value for `key`.
    func set(_ value: String, for key: SecureStorageKey) async throws
    /// The stored value, or `nil` if absent.
    func string(for key: SecureStorageKey) async throws -> String?
    /// Removes the value for `key`. Removing an absent key is not an error.
    func removeValue(for key: SecureStorageKey) async throws
    /// Removes every value owned by this store.
    func removeAll() async throws
}
