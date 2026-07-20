//
//  FavoritesToggleAdapter.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

import CoreModels
import FeatureFavorites
import FeatureMovieDetails

/// Adapts `FeatureFavorites`' repository to the `FavoriteToggling` port that
/// `FeatureMovieDetails` owns — the composition root is the only place two
/// features meet, so neither imports the other.
struct FavoritesToggleAdapter: FavoriteToggling {
    let repository: any FavoritesRepository

    func isFavorite(movieID: Int) async -> Bool {
        await (try? repository.isFavorite(movieID: movieID)) ?? false
    }

    func setFavorite(_ movie: Movie, isFavorite: Bool) async throws {
        try await repository.setFavorite(movie, isFavorite: isFavorite)
    }
}
