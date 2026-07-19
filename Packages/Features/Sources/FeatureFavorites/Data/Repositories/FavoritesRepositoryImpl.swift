//
//  FavoritesRepositoryImpl.swift
//  TMDB
//
//  Created by Ahmed Raslan on 19/07/2026.
//

import CoreModels
import Networking
import SwiftData

/// Offline-first `FavoritesRepository`: the SwiftData local store is the
/// source of truth, so favorites work fully offline and for guest sessions.
///
/// Reconciling with the TMDB account (pushing toggles, pulling the account's
/// list) is task 4.6 — it wraps the already-built `FavoritesRemoteDataSource`
/// around this local core without changing the public contract.
@MainActor
public struct FavoritesRepositoryImpl: FavoritesRepository {
    private let local: any FavoritesLocalDataSource

    /// Composition-root entry point: wires the internal SwiftData source.
    public init(modelContainer: ModelContainer) {
        self.init(local: FavoritesLocalDataSourceImpl(modelContainer: modelContainer))
    }

    init(local: any FavoritesLocalDataSource) {
        self.local = local
    }

    public func favorites() async throws -> [Movie] {
        try await local.all()
    }

    public func isFavorite(movieID: Int) async throws -> Bool {
        try await local.contains(movieID: movieID)
    }

    public func setFavorite(_ movie: Movie, isFavorite: Bool) async throws {
        if isFavorite {
            try await local.upsert(movie)
        } else {
            try await local.remove(movieID: movie.id)
        }
    }
}
