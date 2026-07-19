//
//  SearchMocks.swift
//  TMDB
//
//  Created by Ahmed Raslan on 19/07/2026.
//

import CoreModels
import Foundation
import Testing
@testable import FeatureSearch

enum MockError: Error {
    case stubbed
}

/// Deterministic movie fixture shared by the Search test suites.
func searchTestMovie(_ id: Int) -> Movie {
    Movie(id: id, title: "Movie \(id)", overview: "")
}

/// In-memory `RecentSearchesRepository` — most-recent-first, deduping,
/// trimming — with no SwiftData so it's usable in any test context.
@MainActor
final class RecentSearchesRepositoryMock: RecentSearchesRepository {
    private var queries: [String] = []
    private(set) var recordedCount = 0

    func recent(limit: Int) async throws -> [String] {
        guard limit > 0 else { return [] }
        return Array(queries.prefix(limit))
    }

    func record(_ query: String) async throws {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        recordedCount += 1
        queries.removeAll { $0 == trimmed }
        queries.insert(trimmed, at: 0)
    }

    func delete(_ query: String) async throws {
        queries.removeAll { $0 == query.trimmingCharacters(in: .whitespacesAndNewlines) }
    }

    func clear() async throws {
        queries.removeAll()
    }
}

/// Polls `condition` with tiny sleeps; fails the test on timeout instead of
/// hanging the suite. Real sleeps are required — the debounce sleeps in wall
/// time, so yield-spinning would never let it elapse.
@MainActor
func waitUntil(_ description: String, condition: () -> Bool) async {
    for _ in 0 ..< 400 where !condition() {
        try? await Task.sleep(for: .milliseconds(5))
    }
    if !condition() {
        Issue.record("timed out waiting for \(description)")
    }
}

/// Results and gates keyed by "query#page" so tests can hold one search in
/// flight while another lands.
@MainActor
final class SearchUseCaseMock: SearchMoviesUseCase {
    var results: [String: Result<MoviePage, Error>] = [:]
    var gatedKeys: Set<String> = []
    private(set) var requests: [(query: String, page: Int)] = []
    private var continuations: [String: CheckedContinuation<Void, Never>] = [:]

    private func key(_ query: String, _ page: Int) -> String {
        "\(query)#\(page)"
    }

    func execute(query: String, page: Int) async throws -> MoviePage {
        requests.append((query, page))
        let key = key(query, page)
        if gatedKeys.contains(key) {
            if continuations[key] != nil {
                Issue.record("second gated request for \(key) while one is already suspended")
            } else {
                await withCheckedContinuation { continuations[key] = $0 }
            }
        }
        guard let result = results[key] else {
            throw MockError.stubbed
        }
        return try result.get()
    }

    func stub(_ query: String, page: Int = 1, ids: ClosedRange<Int>, totalPages: Int = 1) {
        results[key(query, page)] = .success(MoviePage(
            page: page,
            movies: ids.map(searchTestMovie),
            totalPages: totalPages
        ))
    }

    func stubEmpty(_ query: String) {
        results[key(query, 1)] = .success(MoviePage(page: 1, movies: [], totalPages: 1))
    }

    func gate(_ query: String, page: Int = 1) {
        gatedKeys.insert(key(query, page))
    }

    func release(_ query: String, page: Int = 1) {
        continuations.removeValue(forKey: key(query, page))?.resume()
    }

    func hasPending(_ query: String, page: Int = 1) -> Bool {
        continuations[key(query, page)] != nil
    }
}
