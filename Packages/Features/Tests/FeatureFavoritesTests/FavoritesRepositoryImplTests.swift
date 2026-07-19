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

/// Local CRUD + remote-push behavior of the repository (merge sync lives in
/// `FavoritesSyncTests`).
@MainActor
@Suite("FavoritesRepositoryImpl")
struct FavoritesRepositoryImplTests {
    private enum MockError: Error { case remote }

    private let local = FavoritesLocalMock()
    private let remote = FavoritesRemoteMock()
    private let provider = FavoritesAccountProviderMock()
    private let repository: FavoritesRepositoryImpl

    init() {
        repository = FavoritesRepositoryImpl(local: local, remote: remote, accountProvider: provider)
    }

    @Test("favorites and isFavorite read through the local source")
    func reads() async throws {
        try await local.upsert(favoriteTestMovie(550))

        #expect(try await repository.favorites().map(\.id) == [550])
        #expect(try await repository.isFavorite(movieID: 550))
        #expect(try await repository.isFavorite(movieID: 1) == false)
    }

    @Test("setFavorite writes local; with no account it does not touch remote")
    func setFavoriteLocalOnlyWhenGuest() async throws {
        try await repository.setFavorite(favoriteTestMovie(550), isFavorite: true)

        #expect(local.upserted.map(\.id) == [550])
        #expect(remote.pushed.isEmpty, "guest / logged-out must not push")
    }

    @Test("setFavorite pushes to remote when an account is available")
    func setFavoritePushes() async throws {
        provider.account = .testAccount

        try await repository.setFavorite(favoriteTestMovie(550), isFavorite: true)
        try await repository.setFavorite(favoriteTestMovie(550), isFavorite: false)

        #expect(remote.pushed.map(\.movieID) == [550, 550])
        #expect(remote.pushed.map(\.isFavorite) == [true, false])
        #expect(local.removed == [550], "local reflects the un-favorite")
    }

    @Test("a remote push failure is swallowed — the local write still stands (offline-first)")
    func remotePushFailureIsSwallowed() async throws {
        provider.account = .testAccount
        remote.setFavoriteError = MockError.remote

        try await repository.setFavorite(favoriteTestMovie(550), isFavorite: true)

        #expect(try await repository.isFavorite(movieID: 550), "local favorite persists despite push failure")
    }
}
