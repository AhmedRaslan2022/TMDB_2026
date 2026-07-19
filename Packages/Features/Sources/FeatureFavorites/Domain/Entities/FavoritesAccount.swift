//
//  FavoritesAccount.swift
//  TMDB
//
//  Created by Ahmed Raslan on 19/07/2026.
//

/// The authenticated TMDB account favorites sync targets. Only non-guest
/// sessions have one; guests and logged-out users have `nil` (see
/// `FavoritesAccountProviding`), and sync becomes a no-op.
public struct FavoritesAccount: Sendable, Hashable {
    public let accountID: Int
    public let sessionID: String

    public init(accountID: Int, sessionID: String) {
        self.accountID = accountID
        self.sessionID = sessionID
    }
}
