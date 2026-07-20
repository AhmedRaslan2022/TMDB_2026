//
//  WatchlistToggleAdapter.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

import CoreModels
import FeatureFavorites
import FeatureMovieDetails

/// Adapts `FeatureFavorites`' watchlist repository to the `WatchlistToggling`
/// port owned by `FeatureMovieDetails` — twin of `FavoritesToggleAdapter`.
struct WatchlistToggleAdapter: WatchlistToggling {
    let repository: any WatchlistRepository

    func isOnWatchlist(movieID: Int) async -> Bool {
        await (try? repository.isOnWatchlist(movieID: movieID)) ?? false
    }

    func setOnWatchlist(_ movie: Movie, isOnWatchlist: Bool) async throws {
        try await repository.setOnWatchlist(movie, isOnWatchlist: isOnWatchlist)
    }
}
