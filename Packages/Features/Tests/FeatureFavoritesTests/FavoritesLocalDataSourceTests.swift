//
//  FavoritesLocalDataSourceTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 19/07/2026.
//

import CoreModels
import Foundation
import SwiftData
import SwiftDataStorage
import Testing
@testable import FeatureFavorites

/// Serialized + dedicated-context SwiftData suite — see the recent-searches
/// store for why `mainContext` can't be used on the macOS host test runner.
@MainActor
@Suite("FavoritesLocalDataSource", .serialized)
struct FavoritesLocalDataSourceTests {
    private let source: FavoritesLocalDataSourceImpl

    init() throws {
        let container = try ModelContainerFactory.make(inMemory: true)
        source = FavoritesLocalDataSourceImpl(modelContainer: container)
    }

    private func movie(_ id: Int, title: String = "Movie") -> Movie {
        Movie(id: id, title: title, overview: "", posterPath: "/p\(id).jpg")
    }

    @Test("upsert then all returns the favorite")
    func upsertAndRead() async throws {
        try await source.upsert(movie(550, title: "Fight Club"))

        let all = try await source.all()
        #expect(all.map(\.id) == [550])
        #expect(all.first?.title == "Fight Club")
        #expect(all.first?.posterPath == "/p550.jpg")
    }

    @Test("upserting an existing id refreshes it without duplicating")
    func upsertUpdates() async throws {
        try await source.upsert(movie(550, title: "Fight Club"))
        try await source.upsert(movie(550, title: "Fight Club (Director's Cut)"))

        let all = try await source.all()
        #expect(all.count == 1)
        #expect(all.first?.title == "Fight Club (Director's Cut)")
    }

    @Test("contains reflects membership")
    func contains() async throws {
        try await source.upsert(movie(550))

        #expect(try await source.contains(movieID: 550))
        #expect(try await source.contains(movieID: 999) == false)
    }

    @Test("remove deletes a favorite; absent is a no-op")
    func remove() async throws {
        try await source.upsert(movie(550))

        try await source.remove(movieID: 550)
        try await source.remove(movieID: 12345)

        #expect(try await source.all().isEmpty)
    }

    @Test("all is ordered most-recently-added first")
    func recencyOrder() async throws {
        try await source.upsert(movie(1))
        try await Task.sleep(for: .milliseconds(5))
        try await source.upsert(movie(2))
        try await Task.sleep(for: .milliseconds(5))
        try await source.upsert(movie(3))

        #expect(try await source.all().map(\.id) == [3, 2, 1])
    }
}
