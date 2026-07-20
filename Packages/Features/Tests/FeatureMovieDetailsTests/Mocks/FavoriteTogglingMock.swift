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

@MainActor
final class MovieRatingRepositoryMock: MovieRatingRepository {
    var initialRating: Double?
    var ratingError: Error?
    var setError: Error?
    private(set) var setCalls: [Double?] = []

    func rating(movieID _: Int) async throws -> Double? {
        if let ratingError {
            throw ratingError
        }
        return initialRating
    }

    func setRating(_ value: Double?, movieID _: Int) async throws {
        if let setError {
            throw setError
        }
        setCalls.append(value)
    }
}

@MainActor
final class WatchlistTogglingMock: WatchlistToggling {
    var initialIsOnWatchlist = false
    var setError: Error?
    private(set) var setCalls: [(movieID: Int, isOnWatchlist: Bool)] = []

    func isOnWatchlist(movieID _: Int) async -> Bool {
        initialIsOnWatchlist
    }

    func setOnWatchlist(_ movie: Movie, isOnWatchlist: Bool) async throws {
        if let setError {
            throw setError
        }
        setCalls.append((movie.id, isOnWatchlist))
    }
}
