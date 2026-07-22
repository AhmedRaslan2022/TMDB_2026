//
//  MovieDetailsFavoriteTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

import CoreModels
import Foundation
import Testing
@testable import FeatureMovieDetails

/// Optimistic favorite toggle + rollback in the details view model.
@MainActor
@Suite("MovieDetailsViewModel favorite toggle")
struct MovieDetailsFavoriteTests {
    private enum MockError: Error { case write }

    @MainActor
    private final class FetchMock: FetchMovieDetailsUseCase {
        var bundle = MovieDetailsBundle(
            details: MovieDetails(id: 550, title: "Fight Club", overview: "…", posterPath: "/p.jpg")
        )
        func execute(movieID _: Int) async throws -> MovieDetailsBundle {
            bundle
        }
    }

    private let fetch = FetchMock()
    private let favorites = FavoriteTogglingMock()
    private let watchlistMock = WatchlistTogglingMock()
    private let ratingMock = MovieRatingRepositoryMock()

    private func makeViewModel() throws -> MovieDetailsViewModel {
        try MovieDetailsViewModel(
            movieID: 550,
            fetchDetails: fetch,
            favorites: favorites,
            watchlist: watchlistMock,
            rating: ratingMock,
            imageBaseURL: #require(URL(string: "https://img.invalid/t/p"))
        )
    }

    @Test("initial favorite state is read on load")
    func loadsInitialState() async throws {
        favorites.initialIsFavorite = true
        let viewModel = try makeViewModel()

        await viewModel.load()

        #expect(viewModel.isFavorite)
    }

    @Test("toggle flips optimistically and persists")
    func togglePersists() async throws {
        let viewModel = try makeViewModel()
        await viewModel.load()

        await viewModel.toggleFavorite()

        #expect(viewModel.isFavorite)
        #expect(favorites.setCalls.map(\.movieID) == [550])
        #expect(favorites.setCalls.map(\.isFavorite) == [true])
    }

    @Test("un-favoriting persists the off state")
    func toggleOff() async throws {
        favorites.initialIsFavorite = true
        let viewModel = try makeViewModel()
        await viewModel.load()

        await viewModel.toggleFavorite()

        #expect(viewModel.isFavorite == false)
        #expect(favorites.setCalls.map(\.isFavorite) == [false])
    }

    @Test("a failed write rolls the optimistic flip back")
    func rollbackOnFailure() async throws {
        let viewModel = try makeViewModel()
        await viewModel.load()
        favorites.setFavoriteError = MockError.write

        await viewModel.toggleFavorite()

        #expect(viewModel.isFavorite == false, "rolled back to the pre-toggle state")
    }

    @Test("toggle is a no-op before the bundle loads")
    func noOpBeforeLoad() async throws {
        let viewModel = try makeViewModel()

        await viewModel.toggleFavorite()

        #expect(favorites.setCalls.isEmpty)
        #expect(viewModel.isFavorite == false)
    }

    @Test("watchlist toggle flips optimistically and persists; rolls back on failure")
    func watchlistToggle() async throws {
        let viewModel = try makeViewModel()
        await viewModel.load()

        await viewModel.toggleWatchlist()
        #expect(viewModel.isOnWatchlist)
        #expect(watchlistMock.setCalls.map(\.isOnWatchlist) == [true])

        watchlistMock.setError = MockError.write
        await viewModel.toggleWatchlist()
        #expect(viewModel.isOnWatchlist, "failed un-watchlist rolls back to on")
    }

    @Test("watchlist initial state is read on load")
    func watchlistInitialState() async throws {
        watchlistMock.initialIsOnWatchlist = true
        let viewModel = try makeViewModel()

        await viewModel.load()

        #expect(viewModel.isOnWatchlist)
    }

    @Test("existing rating is read on load")
    func ratingInitialState() async throws {
        ratingMock.initialRating = 8
        let viewModel = try makeViewModel()

        await viewModel.load()

        #expect(viewModel.userRating == 8)
    }

    @Test("a failed rating read still loads the screen as unrated")
    func ratingReadFailureIsTolerated() async throws {
        ratingMock.ratingError = MockError.write
        let viewModel = try makeViewModel()

        await viewModel.load()

        #expect(viewModel.userRating == nil)
        guard case .loaded = viewModel.state else {
            Issue.record("expected .loaded despite the rating read failing")
            return
        }
    }

    @Test("rating flips optimistically and persists")
    func ratePersists() async throws {
        let viewModel = try makeViewModel()
        await viewModel.load()

        await viewModel.rate(8)

        #expect(viewModel.userRating == 8)
        #expect(ratingMock.setCalls == [8])
    }

    @Test("clearing an existing rating persists the removal")
    func clearRating() async throws {
        ratingMock.initialRating = 6
        let viewModel = try makeViewModel()
        await viewModel.load()

        await viewModel.clearRating()

        #expect(viewModel.userRating == nil)
        #expect(ratingMock.setCalls == [Double?.none])
    }

    @Test("clearing when unrated is a no-op")
    func clearWhenUnratedNoOp() async throws {
        let viewModel = try makeViewModel()
        await viewModel.load()

        await viewModel.clearRating()

        #expect(ratingMock.setCalls.isEmpty)
    }

    @Test("a failed rating write rolls the optimistic value back")
    func rateRollback() async throws {
        ratingMock.initialRating = 4
        let viewModel = try makeViewModel()
        await viewModel.load()
        ratingMock.setError = MockError.write

        await viewModel.rate(10)

        #expect(viewModel.userRating == 4, "rolled back to the pre-rating value")
    }

    @Test("rating is a no-op before the bundle loads")
    func rateBeforeLoadNoOp() async throws {
        let viewModel = try makeViewModel()

        await viewModel.rate(8)

        #expect(ratingMock.setCalls.isEmpty)
        #expect(viewModel.userRating == nil)
    }
}
