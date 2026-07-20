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

    private func makeViewModel() throws -> MovieDetailsViewModel {
        try MovieDetailsViewModel(
            movieID: 550,
            fetchDetails: fetch,
            favorites: favorites,
            watchlist: watchlistMock,
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
}
