//
//  FavoritesRepositoryImplTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 19/07/2026.
//

import CoreModels
import Foundation
import Testing
@testable import FeatureFavorites

@MainActor
@Suite("FavoritesRepositoryImpl")
struct FavoritesRepositoryImplTests {
    /// In-memory local source — no SwiftData, so the repository's coordination
    /// is tested in isolation from persistence.
    @MainActor
    private final class LocalMock: FavoritesLocalDataSource {
        private(set) var movies: [Movie] = []
        private(set) var upserted: [Movie] = []
        private(set) var removed: [Int] = []

        func all() async throws -> [Movie] {
            movies
        }

        func contains(movieID: Int) async throws -> Bool {
            movies.contains { $0.id == movieID }
        }

        func upsert(_ movie: Movie) async throws {
            upserted.append(movie)
            movies.removeAll { $0.id == movie.id }
            movies.insert(movie, at: 0)
        }

        func remove(movieID: Int) async throws {
            removed.append(movieID)
            movies.removeAll { $0.id == movieID }
        }
    }

    private let local = LocalMock()
    private let repository: FavoritesRepositoryImpl

    init() {
        repository = FavoritesRepositoryImpl(local: local)
    }

    private func movie(_ id: Int) -> Movie {
        Movie(id: id, title: "Movie \(id)", overview: "")
    }

    @Test("favorites reads through the local source")
    func favoritesReadsLocal() async throws {
        try await local.upsert(movie(550))

        #expect(try await repository.favorites().map(\.id) == [550])
    }

    @Test("isFavorite reflects local membership")
    func isFavorite() async throws {
        try await local.upsert(movie(550))

        #expect(try await repository.isFavorite(movieID: 550))
        #expect(try await repository.isFavorite(movieID: 1) == false)
    }

    @Test("setFavorite(true) upserts locally")
    func setFavoriteAdds() async throws {
        try await repository.setFavorite(movie(550), isFavorite: true)

        #expect(local.upserted.map(\.id) == [550])
        #expect(try await repository.isFavorite(movieID: 550))
    }

    @Test("setFavorite(false) removes locally")
    func setFavoriteRemoves() async throws {
        try await local.upsert(movie(550))

        try await repository.setFavorite(movie(550), isFavorite: false)

        #expect(local.removed == [550])
        #expect(try await repository.favorites().isEmpty)
    }
}
