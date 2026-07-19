//
//  FavoritesRepository.swift
//  TMDB
//
//  Created by Ahmed Raslan on 19/07/2026.
//

import CoreModels

/// Offline-first access to the user's favorite movies. The local store is the
/// source of truth for the UI; syncing with the TMDB account (task 4.6) is
/// layered on top without changing this contract.
public protocol FavoritesRepository: Sendable {
    /// Current favorites, most-recently-added first.
    func favorites() async throws -> [Movie]
    /// Whether `movieID` is currently favorited.
    func isFavorite(movieID: Int) async throws -> Bool
    /// Adds or removes `movie` from favorites. Applied locally first
    /// (offline-first), then pushed to the account when authenticated.
    func setFavorite(_ movie: Movie, isFavorite: Bool) async throws
    /// Reconciles local favorites with the account's remote favorites when
    /// authenticated. A no-op for guests / logged-out users.
    func synchronize() async throws
}
