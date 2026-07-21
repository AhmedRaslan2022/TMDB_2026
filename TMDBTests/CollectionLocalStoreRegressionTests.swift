//
//  CollectionLocalStoreRegressionTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 21/07/2026.
//

import CoreModels
import FeatureFavorites
import Foundation
import Networking
import SwiftDataStorage
import Testing

/// Drives the REAL generic SwiftData collection source through
/// `FavoritesRepositoryImpl` against an in-memory container. Unlike the
/// FeatureFavorites package tests (which run on the tolerant macOS host), this
/// app-target suite runs on the **iOS simulator** — the platform where a
/// generic `SortDescriptor(\Model.addedAt)` keypath crashed. It guards that
/// regression: reintroducing a SwiftData-level sort here would trap the run.
@MainActor
@Suite("Collection local store (on-device SwiftData)")
struct CollectionLocalStoreRegressionTests {
    private struct GuestAccountProvider: FavoritesAccountProviding {
        func currentAccount() async -> FavoritesAccount? {
            nil
        }
    }

    private func makeRepository() throws -> FavoritesRepositoryImpl {
        try FavoritesRepositoryImpl(
            modelContainer: ModelContainerFactory.make(inMemory: true),
            apiClient: URLSessionAPIClient(baseURL: URL(fileURLWithPath: "/")),
            accountProvider: GuestAccountProvider()
        )
    }

    @Test("reading favorites sorts most-recent-first without crashing on-device")
    func readsSortedWithoutCrashing() async throws {
        let repository = try makeRepository()
        try await repository.setFavorite(Movie(id: 1, title: "A", overview: ""), isFavorite: true)
        try await repository.setFavorite(Movie(id: 2, title: "B", overview: ""), isFavorite: true)
        try await repository.setFavorite(Movie(id: 3, title: "C", overview: ""), isFavorite: true)

        let favorites = try await repository.favorites()

        #expect(favorites.map(\.id) == [3, 2, 1], "most-recently-added first")
    }

    @Test("membership and removal round-trip through the real store")
    func membershipRoundTrips() async throws {
        let repository = try makeRepository()
        try await repository.setFavorite(Movie(id: 5, title: "X", overview: ""), isFavorite: true)

        #expect(try await repository.isFavorite(movieID: 5))
        #expect(try await repository.isFavorite(movieID: 99) == false)

        try await repository.setFavorite(Movie(id: 5, title: "X", overview: ""), isFavorite: false)
        #expect(try await repository.isFavorite(movieID: 5) == false)
    }
}
