//
//  FavoriteToggling.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

import CoreModels

/// The favorites capability the details screen needs — a port owned by this
/// feature so it stays ignorant of `FeatureFavorites`. The composition root
/// adapts the favorites repository to this protocol (features never import
/// each other).
public protocol FavoriteToggling: Sendable {
    /// Current favorite state; errors resolve to `false` (not favorited).
    func isFavorite(movieID: Int) async -> Bool
    /// Persists the favorite state. Throws on failure so the caller can roll
    /// back its optimistic UI.
    func setFavorite(_ movie: Movie, isFavorite: Bool) async throws
}
