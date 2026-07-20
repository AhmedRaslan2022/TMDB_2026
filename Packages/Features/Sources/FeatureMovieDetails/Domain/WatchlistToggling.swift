//
//  WatchlistToggling.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

import CoreModels

/// The watchlist capability the details screen needs — a port owned by this
/// feature (like `FavoriteToggling`), adapted to `FeatureFavorites`' watchlist
/// repository in the composition root.
public protocol WatchlistToggling: Sendable {
    func isOnWatchlist(movieID: Int) async -> Bool
    func setOnWatchlist(_ movie: Movie, isOnWatchlist: Bool) async throws
}
