//
//  FavoritesRepositoryImpl.swift
//  TMDB
//
//  Created by Ahmed Raslan on 19/07/2026.
//

import CoreModels
import Networking
import SwiftData
import SwiftDataStorage

/// `FavoritesRepository` as a thin specialization of the shared
/// `MovieCollectionStore` (task 5.3): favorites-specific method names over the
/// generic offline-first + sync engine.
@MainActor
public struct FavoritesRepositoryImpl: FavoritesRepository {
    private let store: MovieCollectionStore

    /// Composition-root entry point.
    public init(
        modelContainer: ModelContainer,
        apiClient: any APIClient,
        accountProvider: any FavoritesAccountProviding
    ) {
        self.init(store: MovieCollectionStore(
            collection: .favorites,
            local: MovieCollectionLocalDataSourceImpl<FavoriteMovie>(modelContainer: modelContainer),
            remote: MovieCollectionRemoteDataSourceImpl(apiClient: apiClient),
            accountProvider: accountProvider
        ))
    }

    init(store: MovieCollectionStore) {
        self.store = store
    }

    public func favorites() async throws -> [Movie] {
        try await store.movies()
    }

    public func isFavorite(movieID: Int) async throws -> Bool {
        try await store.contains(movieID: movieID)
    }

    public func setFavorite(_ movie: Movie, isFavorite: Bool) async throws {
        try await store.setMembership(movie, isMember: isFavorite)
    }

    public func synchronize() async throws {
        try await store.synchronize()
    }
}
