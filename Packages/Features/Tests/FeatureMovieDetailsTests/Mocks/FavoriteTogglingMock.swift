//
//  FavoriteTogglingMock.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

import CoreModels
@testable import FeatureMovieDetails

@MainActor
final class FavoriteTogglingMock: FavoriteToggling {
    var initialIsFavorite = false
    var setFavoriteError: Error?
    private(set) var setCalls: [(movieID: Int, isFavorite: Bool)] = []

    func isFavorite(movieID _: Int) async -> Bool {
        initialIsFavorite
    }

    func setFavorite(_ movie: Movie, isFavorite: Bool) async throws {
        if let setFavoriteError {
            throw setFavoriteError
        }
        setCalls.append((movie.id, isFavorite))
    }
}
