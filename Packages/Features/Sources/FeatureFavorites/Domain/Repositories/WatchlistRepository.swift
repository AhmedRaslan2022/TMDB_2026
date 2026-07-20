//
//  WatchlistRepository.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

import CoreModels

/// Offline-first access to the user's watchlist — the second synced
/// collection, sharing all of favorites' plumbing (task 5.3).
public protocol WatchlistRepository: Sendable {
    /// Watchlist entries, most-recently-added first.
    func watchlist() async throws -> [Movie]
    /// Whether `movieID` is on the watchlist.
    func isOnWatchlist(movieID: Int) async throws -> Bool
    /// Adds or removes `movie`; local-first, then pushed to the account.
    func setOnWatchlist(_ movie: Movie, isOnWatchlist: Bool) async throws
    /// Reconciles the local watchlist with the account's remote watchlist.
    func synchronize() async throws
}
