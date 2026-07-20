//
//  CollectionIntegrationTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

import CoreModels
import Foundation
import Networking
import SwiftData
import SwiftDataStorage
import Testing
@testable import FeatureFavorites

/// The store + repositories against the REAL generic SwiftData local source
/// (in-memory) with a mocked remote — proves the shared plumbing persists for
/// BOTH models. Serialized + dedicated-context per the host-testing pattern.
@MainActor
@Suite("Collection integration", .serialized)
struct CollectionIntegrationTests {
    private let container: ModelContainer
    private let remote = CollectionRemoteMock()

    init() throws {
        container = try ModelContainerFactory.make(inMemory: true)
    }

    private func favoritesStore() -> MovieCollectionStore {
        MovieCollectionStore(
            collection: .favorites,
            local: MovieCollectionLocalDataSourceImpl<FavoriteMovie>(modelContainer: container),
            remote: remote,
            accountProvider: FavoritesAccountProviderMock(account: .testAccount)
        )
    }

    @Test("favorites sync writes remote-only entries into SwiftData and pushes local-only up")
    func favoritesSyncPersists() async throws {
        let store = favoritesStore()
        try await store.setMembership(favoriteTestMovie(1), isMember: true) // local-only
        remote.stubPage(1, ids: [2], totalPages: 1) // remote-only

        try await store.synchronize()

        #expect(try await store.movies().map(\.id).sorted() == [1, 2])
        #expect(remote.pushed.contains { $0.movieID == 2 } == false, "movie 2 came from remote, not pushed back")
    }

    @Test("entries come back most-recently-added first, proving the generic reverse-addedAt sort")
    func recencyOrderFromRealStore() async throws {
        let store = favoritesStore()
        // Sequential sets → strictly increasing `addedAt`; reverse sort ⇒ [3, 2, 1].
        try await store.setMembership(favoriteTestMovie(1), isMember: true)
        try await store.setMembership(favoriteTestMovie(2), isMember: true)
        try await store.setMembership(favoriteTestMovie(3), isMember: true)

        #expect(try await store.movies().map(\.id) == [3, 2, 1])
    }

    @Test("re-adding an existing entry refreshes its title but preserves addedAt, so it doesn't jump to the front")
    func upsertPreservesAddedAt() async throws {
        let store = favoritesStore()
        try await store.setMembership(favoriteTestMovie(1), isMember: true) // oldest
        try await store.setMembership(favoriteTestMovie(2), isMember: true) // newest

        // Re-add 1 with a fresh title; addedAt must stay put, so order is unchanged.
        try await store.setMembership(Movie(id: 1, title: "Renamed", overview: ""), isMember: true)

        let movies = try await store.movies()
        #expect(movies.map(\.id) == [2, 1], "re-adding must not reorder by re-stamping addedAt")
        #expect(movies.first(where: { $0.id == 1 })?.title == "Renamed", "upsert refreshes the title")
    }

    @Test("watchlist persists to its own model, isolated from favorites")
    func watchlistIsolatedFromFavorites() async throws {
        // Guest account provider → no network; the shared session is never hit.
        let apiClient = URLSessionAPIClient(baseURL: URL(fileURLWithPath: "/"), session: .shared)
        let watchlist = WatchlistRepositoryImpl(
            modelContainer: container, apiClient: apiClient, accountProvider: FavoritesAccountProviderMock()
        )
        let favorites = FavoritesRepositoryImpl(
            modelContainer: container, apiClient: apiClient, accountProvider: FavoritesAccountProviderMock()
        )

        try await watchlist.setOnWatchlist(Movie(id: 7, title: "W", overview: ""), isOnWatchlist: true)

        #expect(try await watchlist.watchlist().map(\.id) == [7])
        #expect(try await favorites.favorites().isEmpty, "watchlist writes don't leak into favorites")
    }
}
