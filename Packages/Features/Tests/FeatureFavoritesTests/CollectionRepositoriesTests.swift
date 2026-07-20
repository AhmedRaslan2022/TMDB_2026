//
//  CollectionRepositoriesTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

import CoreModels
import Testing
@testable import FeatureFavorites

/// The thin favorites/watchlist repositories over the shared store: each
/// public API round-trips through the local source and pushes under its OWN
/// collection when authenticated (task 5.7 — repository contracts).
@MainActor
@Suite("Collection repositories")
struct CollectionRepositoriesTests {
    private let local = CollectionLocalMock()
    private let remote = CollectionRemoteMock()
    private let provider = FavoritesAccountProviderMock(account: .testAccount)

    private func store(_ collection: MovieCollection) -> MovieCollectionStore {
        MovieCollectionStore(collection: collection, local: local, remote: remote, accountProvider: provider)
    }

    // MARK: Favorites

    @Test("favorites repository writes locally and pushes under .favorites")
    func favoritesContract() async throws {
        let repository = FavoritesRepositoryImpl(store: store(.favorites))

        try await repository.setFavorite(favoriteTestMovie(550), isFavorite: true)

        #expect(try await repository.isFavorite(movieID: 550))
        #expect(try await repository.favorites().map(\.id) == [550])
        #expect(remote.pushed == [CollectionPush(collection: .favorites, movieID: 550, isMember: true)])
    }

    @Test("favorites repository removal pushes isMember=false")
    func favoritesRemoval() async throws {
        let repository = FavoritesRepositoryImpl(store: store(.favorites))
        local.seed([550])

        try await repository.setFavorite(favoriteTestMovie(550), isFavorite: false)

        #expect(try await repository.isFavorite(movieID: 550) == false)
        #expect(remote.pushed == [CollectionPush(collection: .favorites, movieID: 550, isMember: false)])
    }

    // MARK: Watchlist

    @Test("watchlist repository writes locally and pushes under .watchlist")
    func watchlistContract() async throws {
        let repository = WatchlistRepositoryImpl(store: store(.watchlist))

        try await repository.setOnWatchlist(favoriteTestMovie(777), isOnWatchlist: true)

        #expect(try await repository.isOnWatchlist(movieID: 777))
        #expect(try await repository.watchlist().map(\.id) == [777])
        #expect(remote.pushed == [CollectionPush(collection: .watchlist, movieID: 777, isMember: true)])
    }

    @Test("watchlist repository synchronize pulls remote-only entries into the local store")
    func watchlistSync() async throws {
        let repository = WatchlistRepositoryImpl(store: store(.watchlist))
        remote.stubPage(1, ids: [42], totalPages: 1)

        try await repository.synchronize()

        #expect(try await repository.watchlist().map(\.id) == [42])
    }
}
