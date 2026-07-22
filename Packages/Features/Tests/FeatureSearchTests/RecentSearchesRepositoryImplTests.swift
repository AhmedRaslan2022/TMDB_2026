//
//  RecentSearchesRepositoryImplTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 19/07/2026.
//

import Foundation
import SwiftData
import SwiftDataStorage
import Testing
@testable import FeatureSearch

/// A hand-cranked clock so recency ordering is deterministic without sleeps.
private final class TestClock: @unchecked Sendable {
    private let lock = NSLock()
    private var current: Date

    init(_ start: Date = Date(timeIntervalSince1970: 1_000_000)) {
        current = start
    }

    func now() -> Date {
        lock.lock(); defer { lock.unlock() }
        return current
    }

    /// Advances the clock and returns it, so each recorded row gets a later
    /// timestamp than the last.
    func tick() {
        lock.lock(); defer { lock.unlock() }
        current += 1
    }
}

@MainActor
@Suite("RecentSearchesRepositoryImpl", .serialized)
struct RecentSearchesRepositoryImplTests {
    private let clock = TestClock()
    private let repository: RecentSearchesRepositoryImpl

    init() throws {
        let container = try ModelContainerFactory.make(inMemory: true)
        let clock = clock
        repository = RecentSearchesRepositoryImpl(modelContainer: container, now: { clock.now() })
    }

    /// Records each query with a strictly increasing timestamp.
    private func record(_ queries: String...) async throws {
        for query in queries {
            clock.tick()
            try await repository.record(query)
        }
    }

    @Test("recorded queries read back most-recent-first")
    func recencyOrder() async throws {
        try await record("dune", "blade runner", "arrival")

        #expect(try await repository.recent(limit: 10) == ["arrival", "blade runner", "dune"])
    }

    @Test("re-recording an existing query refreshes recency without duplicating")
    func refreshesInsteadOfDuplicating() async throws {
        try await record("dune", "blade runner")
        try await record("dune")

        let recent = try await repository.recent(limit: 10)
        #expect(recent == ["dune", "blade runner"], "dune moves to front, no duplicate")
    }

    @Test("record trims and ignores blank queries")
    func trimsAndIgnoresBlank() async throws {
        try await record("  dune  ", "", "   ")

        #expect(try await repository.recent(limit: 10) == ["dune"])
    }

    @Test("recent respects the limit")
    func respectsLimit() async throws {
        try await record("a", "b", "c", "d")

        #expect(try await repository.recent(limit: 2) == ["d", "c"])
    }

    @Test("a non-positive limit returns nothing (guards SwiftData's 0-means-unlimited)")
    func nonPositiveLimit() async throws {
        try await record("dune", "arrival")

        #expect(try await repository.recent(limit: 0).isEmpty)
        #expect(try await repository.recent(limit: -3).isEmpty)
    }

    @Test("delete removes a single query; absent is a no-op")
    func deleteOne() async throws {
        try await record("dune", "arrival")

        try await repository.delete("dune")
        try await repository.delete("never recorded")

        #expect(try await repository.recent(limit: 10) == ["arrival"])
    }

    @Test("clear removes everything")
    func clearAll() async throws {
        try await record("dune", "arrival")

        try await repository.clear()

        #expect(try await repository.recent(limit: 10).isEmpty)
    }

    @Test("recording beyond the cap prunes the oldest entries")
    func prunesBeyondCap() async throws {
        // 25 distinct queries, oldest first; only the newest 20 survive.
        for index in 1 ... 25 {
            clock.tick()
            try await repository.record("q\(index)")
        }

        let recent = try await repository.recent(limit: 100)
        #expect(recent.count == 20)
        #expect(recent.first == "q25")
        #expect(recent.last == "q6", "q1…q5 pruned")
        #expect(!recent.contains("q5"))
    }
}
