//
//  RecentSearchesRepository.swift
//  TMDB
//
//  Created by Ahmed Raslan on 19/07/2026.
//

/// Local persistence for the user's recent search queries. Implemented in the
/// Data layer over SwiftData; the domain deals in plain query strings and
/// never sees the `@Model`.
public protocol RecentSearchesRepository: Sendable {
    /// Recorded queries, most-recent-first, capped at `limit`.
    func recent(limit: Int) async throws -> [String]
    /// Records a search, refreshing recency when the query already exists.
    /// Blank/whitespace queries are ignored.
    func record(_ query: String) async throws
    /// Removes a single recorded query. Removing an absent one is not an error.
    func delete(_ query: String) async throws
    /// Removes every recorded query.
    func clear() async throws
}
