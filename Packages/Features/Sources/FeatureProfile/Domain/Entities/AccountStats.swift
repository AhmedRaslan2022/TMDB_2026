//
//  AccountStats.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

/// Collection counts shown on the profile. TMDB has no single stats endpoint,
/// so these come from the `total_results` of the favorites/watchlist lists.
public struct AccountStats: Equatable, Sendable {
    public let favoriteCount: Int
    public let watchlistCount: Int

    public init(favoriteCount: Int, watchlistCount: Int) {
        self.favoriteCount = favoriteCount
        self.watchlistCount = watchlistCount
    }
}
