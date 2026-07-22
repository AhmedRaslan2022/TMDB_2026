//
//  AuthRepository.swift
//  TMDB
//
//  Created by Ahmed Raslan on 17/07/2026.
//

/// Remote TMDB authentication operations. Implemented in the Data layer
/// (task 2.2); consumers depend on this protocol so tests can mock it.
public protocol AuthRepository: Sendable {
    /// Creates a new, not-yet-approved request token.
    func createRequestToken() async throws -> RequestToken
    /// Exchanges a user-approved request token for an authenticated session.
    func createSession(approvedToken: RequestToken) async throws -> AuthSession
    /// Creates an anonymous guest session.
    func createGuestSession() async throws -> AuthSession
    /// Invalidates an authenticated session on TMDB's side.
    func deleteSession(sessionID: String) async throws
}
