//
//  FavoritesSyncIntegrationTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

import CoreModels
import Foundation
import SwiftData
import SwiftDataStorage
import Testing
@testable import FeatureFavorites

/// Sync against the REAL SwiftData local source (in-memory container) with a
/// mocked remote — proves the merge actually persists, not just that the
/// coordination logic is right (4.6 covered that with an all-mock local).
/// Serialized + dedicated-context per the host-testing pattern.
@MainActor
@Suite("Favorites sync integration", .serialized)
struct FavoritesSyncIntegrationTests {
    private let local: FavoritesLocalDataSourceImpl
    private let remote = FavoritesRemoteMock()
    private let repository: FavoritesRepositoryImpl

    init() throws {
        let container = try ModelContainerFactory.make(inMemory: true)
        local = FavoritesLocalDataSourceImpl(modelContainer: container)
        repository = FavoritesRepositoryImpl(
            local: local,
            remote: remote,
            accountProvider: FavoritesAccountProviderMock(account: .testAccount)
        )
    }

    @Test("sync writes remote-only favorites into SwiftData and pushes local-only up")
    func syncPersistsToStore() async throws {
        try await local.upsert(favoriteTestMovie(1)) // local-only
        remote.stubPage(1, ids: [2], totalPages: 1) // remote-only

        try await repository.synchronize()

        // Remote-only movie 2 is now persisted in the real store.
        #expect(try await local.all().map(\.id).sorted() == [1, 2])
        #expect(try await repository.isFavorite(movieID: 2))
        // Local-only movie 1 was pushed up.
        #expect(remote.pushed.map(\.movieID) == [1])
    }

    @Test("setFavorite persists to SwiftData and the un-favorite removes it")
    func setFavoritePersists() async throws {
        let movie = Movie(id: 550, title: "Fight Club", overview: "", posterPath: "/p.jpg")

        try await repository.setFavorite(movie, isFavorite: true)
        #expect(try await repository.favorites().map(\.id) == [550])
        #expect(remote.pushed.last?.isFavorite == true)

        try await repository.setFavorite(movie, isFavorite: false)
        #expect(try await repository.favorites().isEmpty)
    }
}
