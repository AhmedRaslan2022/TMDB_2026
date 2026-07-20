//
//  MovieCollectionStoreTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

import CoreModels
import Foundation
import Testing
@testable import FeatureFavorites

/// The shared offline-first + sync engine both favorites and watchlist reuse.
@MainActor
@Suite("MovieCollectionStore")
struct MovieCollectionStoreTests {
    private enum MockError: Error, Equatable { case remote }

    private let local = CollectionLocalMock()
    private let remote = CollectionRemoteMock()
    private let provider = FavoritesAccountProviderMock()

    private func makeStore(_ collection: MovieCollection = .favorites) -> MovieCollectionStore {
        MovieCollectionStore(collection: collection, local: local, remote: remote, accountProvider: provider)
    }

    @Test("membership writes local; with no account it doesn't push")
    func localOnlyWhenGuest() async throws {
        try await makeStore().setMembership(favoriteTestMovie(550), isMember: true)

        #expect(local.upserted.map(\.id) == [550])
        #expect(remote.pushed.isEmpty)
    }

    @Test("membership pushes to remote under the collection when authenticated")
    func pushesWithCollection() async throws {
        provider.account = .testAccount

        try await makeStore(.watchlist).setMembership(favoriteTestMovie(550), isMember: true)

        #expect(remote.pushed.map(\.movieID) == [550])
        #expect(remote.pushed.first?.collection == .watchlist, "pushes under the right collection")
    }

    @Test("a remote push failure is swallowed; the local write stands (offline-first)")
    func pushFailureSwallowed() async throws {
        provider.account = .testAccount
        remote.setError = MockError.remote

        try await makeStore().setMembership(favoriteTestMovie(550), isMember: true)

        #expect(try await makeStore().contains(movieID: 550))
    }

    @Test("no account: synchronize is a no-op")
    func syncNoAccount() async throws {
        local.seed([1, 2])

        try await makeStore().synchronize()

        #expect(remote.requestedPages.isEmpty)
        #expect(remote.pushed.isEmpty)
    }

    @Test("union merge: remote-only added local, local-only pushed up")
    func unionMerge() async throws {
        provider.account = .testAccount
        local.seed([1, 2])
        remote.stubPage(1, ids: [2, 3], totalPages: 1)

        try await makeStore().synchronize()

        #expect(try await makeStore().movies().map(\.id).sorted() == [1, 2, 3])
        #expect(local.upserted.map(\.id) == [3])
        #expect(remote.pushed.map(\.movieID) == [1])
    }

    @Test("pulls every page of the remote list")
    func pullsAllPages() async throws {
        provider.account = .testAccount
        remote.stubPage(1, ids: [10, 11], totalPages: 2)
        remote.stubPage(2, ids: [12], totalPages: 2)

        try await makeStore().synchronize()

        #expect(remote.requestedPages == [1, 2])
        #expect(try await makeStore().movies().map(\.id).sorted() == [10, 11, 12])
    }

    @Test("a failed pull propagates and writes nothing")
    func pullFailurePropagates() async {
        provider.account = .testAccount
        local.seed([1])
        remote.listError = MockError.remote

        await #expect(throws: MockError.remote) {
            try await makeStore().synchronize()
        }
        #expect(local.upserted.isEmpty)
    }
}
