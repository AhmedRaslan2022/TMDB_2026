//
//  SwiftDataUserStoreTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 17/07/2026.
//

import Foundation
import SwiftData
import SwiftDataStorage
import Testing
@testable import TMDB

@MainActor
@Suite("SwiftDataUserStore")
struct SwiftDataUserStoreTests {
    private let container: ModelContainer
    private let store: SwiftDataUserStore

    init() throws {
        container = try ModelContainerFactory.make(inMemory: true)
        store = SwiftDataUserStore(modelContainer: container)
    }

    private func count<T: PersistentModel>(_ type: T.Type) throws -> Int {
        try container.mainContext.fetchCount(FetchDescriptor<T>())
    }

    @Test("clearAll deletes favorites and recent searches, keeping the content cache")
    func clearsUserScopedModels() async throws {
        let context = container.mainContext
        context.insert(FavoriteMovie(movieID: 550, title: "Fight Club"))
        context.insert(RecentSearch(query: "fincher"))
        context.insert(CachedMovie(movieID: 550, title: "Fight Club", overview: "…"))
        try context.save()
        try #require(try count(FavoriteMovie.self) == 1)

        try await store.clearAll()

        #expect(try count(FavoriteMovie.self) == 0)
        #expect(try count(RecentSearch.self) == 0)
        // CachedMovie is a non-user cache and is intentionally left intact.
        #expect(try count(CachedMovie.self) == 1)
    }

    @Test("clearAll on an empty store is a no-op success")
    func emptyStoreNoOp() async throws {
        try await store.clearAll()

        #expect(try count(FavoriteMovie.self) == 0)
        #expect(try count(RecentSearch.self) == 0)
    }
}
