//
//  SessionRepository.swift
//  TMDB
//
//  Created by Ahmed Raslan on 17/07/2026.
//

/// Local persistence for the active session. Implemented in the Data layer
/// over `KeychainStorage` (task 2.5); the domain never sees the keychain.
public protocol SessionRepository: Sendable {
    /// The persisted session, or `nil` when logged out.
    func currentSession() async throws -> AuthSession?
    /// Persists `session`, replacing any previous one.
    func save(_ session: AuthSession) async throws
    /// Removes the persisted session. Clearing when absent is not an error.
    func clearSession() async throws
}
