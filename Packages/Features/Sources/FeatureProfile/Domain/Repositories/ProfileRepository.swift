//
//  ProfileRepository.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

/// Account details + collection counts for the signed-in user. Implemented in
/// the Data layer; throws `ProfileError.notAuthenticated` for guests.
public protocol ProfileRepository: Sendable {
    /// Fetches the account and caches its id (for favorites/watchlist sync).
    func account() async throws -> Account
    /// Favorites + watchlist counts for `accountID`.
    func stats(for accountID: Int) async throws -> AccountStats
}
