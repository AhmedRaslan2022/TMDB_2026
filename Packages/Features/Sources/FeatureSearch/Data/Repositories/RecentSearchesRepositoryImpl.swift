//
//  RecentSearchesRepositoryImpl.swift
//  TMDB
//
//  Created by Ahmed Raslan on 19/07/2026.
//

import Foundation
import SwiftData
import SwiftDataStorage

/// `RecentSearchesRepository` backed by SwiftData's `RecentSearch` @Model.
/// `@MainActor`-confined; the row count is bounded by `maxStored`.
///
/// Uses a dedicated `ModelContext(container)` rather than `container.mainContext`
/// on purpose: `mainContext` asserts it runs on the real main thread, which
/// the Swift Testing `@MainActor` executor is not on the macOS host, so it
/// traps under `swift test`. A private context has no such requirement and,
/// as the sole writer of this data, wants its own context anyway. Matching is
/// done by fetching and filtering in Swift (bounded row count).
@MainActor
public final class RecentSearchesRepositoryImpl: RecentSearchesRepository {
    /// Hard cap on stored rows; recording prunes older entries past this.
    private static let maxStored = 20

    private let context: ModelContext
    private let now: @Sendable () -> Date

    /// - Parameter now: Timestamp source; tests inject a controllable clock
    ///   so recency ordering is deterministic.
    public init(modelContainer: ModelContainer, now: @escaping @Sendable () -> Date = { .now }) {
        context = ModelContext(modelContainer)
        self.now = now
    }

    public func recent(limit: Int) async throws -> [String] {
        // SwiftData treats fetchLimit == 0 as "unlimited", so a non-positive
        // limit must short-circuit rather than fall through to it.
        guard limit > 0 else { return [] }
        var descriptor = FetchDescriptor<RecentSearch>(
            sortBy: [SortDescriptor(\.searchedAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return try context.fetch(descriptor).map(\.query)
    }

    public func record(_ query: String) async throws {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let existing = try fetchAllNewestFirst()
        if let match = existing.first(where: { $0.query == trimmed }) {
            match.searchedAt = now()
        } else {
            context.insert(RecentSearch(query: trimmed, searchedAt: now()))
            // `existing` is newest-first, so the oldest rows are at the tail.
            // Keep the new row + the newest (maxStored - 1) of the rest.
            if existing.count >= Self.maxStored {
                for stale in existing[(Self.maxStored - 1)...] {
                    context.delete(stale)
                }
            }
        }
        try context.save()
    }

    public func delete(_ query: String) async throws {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        for match in try fetchAll() where match.query == trimmed {
            context.delete(match)
        }
        try context.save()
    }

    public func clear() async throws {
        for item in try fetchAll() {
            context.delete(item)
        }
        try context.save()
    }

    private func fetchAll() throws -> [RecentSearch] {
        try context.fetch(FetchDescriptor<RecentSearch>())
    }

    private func fetchAllNewestFirst() throws -> [RecentSearch] {
        try context.fetch(FetchDescriptor<RecentSearch>(
            sortBy: [SortDescriptor(\.searchedAt, order: .reverse)]
        ))
    }
}
