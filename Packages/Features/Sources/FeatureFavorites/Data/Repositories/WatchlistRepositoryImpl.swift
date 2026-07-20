//
//  WatchlistRepositoryImpl.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

import CoreModels
import Networking
import SwiftData
import SwiftDataStorage

/// `WatchlistRepository` as a thin specialization of the shared
/// `MovieCollectionStore` (task 5.3) — same engine as favorites, over the
/// `WatchlistMovie` model and the `.watchlist` collection.
@MainActor
public struct WatchlistRepositoryImpl: WatchlistRepository {
    private let store: MovieCollectionStore

    /// Composition-root entry point.
    public init(
        modelContainer: ModelContainer,
        apiClient: any APIClient,
        accountProvider: any FavoritesAccountProviding
    ) {
        self.init(store: MovieCollectionStore(
            collection: .watchlist,
            local: MovieCollectionLocalDataSourceImpl<WatchlistMovie>(modelContainer: modelContainer),
            remote: MovieCollectionRemoteDataSourceImpl(apiClient: apiClient),
            accountProvider: accountProvider
        ))
    }

    init(store: MovieCollectionStore) {
        self.store = store
    }

    public func watchlist() async throws -> [Movie] {
        try await store.movies()
    }

    public func isOnWatchlist(movieID: Int) async throws -> Bool {
        try await store.contains(movieID: movieID)
    }

    public func setOnWatchlist(_ movie: Movie, isOnWatchlist: Bool) async throws {
        try await store.setMembership(movie, isMember: isOnWatchlist)
    }

    public func synchronize() async throws {
        try await store.synchronize()
    }
}
