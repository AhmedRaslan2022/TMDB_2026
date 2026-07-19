//
//  FavoritesSyncTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 19/07/2026.
//

import CoreModels
import Foundation
import Testing
@testable import FeatureFavorites

/// The two-way merge in `FavoritesRepositoryImpl.synchronize()`.
@MainActor
@Suite("FavoritesRepositoryImpl.synchronize")
struct FavoritesSyncTests {
    private enum MockError: Error, Equatable { case remote }

    private let local = FavoritesLocalMock()
    private let remote = FavoritesRemoteMock()
    private let provider = FavoritesAccountProviderMock()
    private let repository: FavoritesRepositoryImpl

    init() {
        repository = FavoritesRepositoryImpl(local: local, remote: remote, accountProvider: provider)
    }

    @Test("no account: synchronize is a no-op — no remote calls, local untouched")
    func noAccountNoOp() async throws {
        local.seed([1, 2])

        try await repository.synchronize()

        #expect(remote.requestedPages.isEmpty)
        #expect(remote.pushed.isEmpty)
        #expect(try await repository.favorites().map(\.id).sorted() == [1, 2])
    }

    @Test("union merge: remote-only favorites are added locally, local-only are pushed up")
    func unionMerge() async throws {
        provider.account = .testAccount
        local.seed([1, 2])
        remote.stubPage(1, ids: [2, 3], totalPages: 1)

        try await repository.synchronize()

        // 3 (remote-only) added locally; 1 and 2 unchanged.
        #expect(try await repository.favorites().map(\.id).sorted() == [1, 2, 3])
        #expect(local.upserted.map(\.id) == [3], "only the remote-only movie is inserted")
        // 1 (local-only) pushed up as a favorite; 2 already on remote.
        #expect(remote.pushed.map(\.movieID) == [1])
        #expect(remote.pushed.map(\.isFavorite) == [true])
    }

    @Test("pulls every page of the remote list")
    func pullsAllPages() async throws {
        provider.account = .testAccount
        remote.stubPage(1, ids: [10, 11], totalPages: 2)
        remote.stubPage(2, ids: [12], totalPages: 2)

        try await repository.synchronize()

        #expect(remote.requestedPages == [1, 2])
        #expect(try await repository.favorites().map(\.id).sorted() == [10, 11, 12])
    }

    @Test("identical lists need no writes")
    func alreadyInSync() async throws {
        provider.account = .testAccount
        local.seed([1, 2])
        remote.stubPage(1, ids: [1, 2], totalPages: 1)

        try await repository.synchronize()

        #expect(local.upserted.isEmpty)
        #expect(remote.pushed.isEmpty)
    }

    @Test("a failed remote pull propagates and writes nothing")
    func pullFailurePropagates() async {
        provider.account = .testAccount
        local.seed([1])
        remote.favoritesError = MockError.remote

        await #expect(throws: MockError.remote) {
            try await repository.synchronize()
        }
        #expect(local.upserted.isEmpty)
    }
}
