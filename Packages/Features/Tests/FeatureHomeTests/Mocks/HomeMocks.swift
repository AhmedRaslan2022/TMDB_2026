//
//  HomeMocks.swift
//  TMDB
//
//  Created by Ahmed Raslan on 18/07/2026.
//

import CoreModels
import Testing
@testable import FeatureHome

enum MockError: Error, Equatable {
    case unstubbed
    case stubbed
}

/// Deterministic movie fixture shared by the Home test suites.
func testMovie(_ id: Int) -> Movie {
    Movie(id: id, title: "Movie \(id)", overview: "")
}

/// Per-list results and per-list gating, so tests can hold one section in
/// flight while others complete — proving the fan-out is parallel.
@MainActor
final class FetchMovieListUseCaseMock: FetchMovieListUseCase {
    var results: [MovieList: Result<MoviePage, Error>] = [:]
    var gatedLists: Set<MovieList> = []
    private(set) var requestedLists: [MovieList] = []
    private var continuations: [MovieList: CheckedContinuation<Void, Never>] = [:]

    func execute(list: MovieList, page _: Int) async throws -> MoviePage {
        requestedLists.append(list)
        if gatedLists.contains(list) {
            if continuations[list] != nil {
                // A second suspended request would leak the first
                // continuation and hang the suite — fail fast instead.
                Issue.record("second gated request for \(list) while one is already suspended")
            } else {
                await withCheckedContinuation { continuations[list] = $0 }
            }
        }
        guard let result = results[list] else {
            throw MockError.unstubbed
        }
        return try result.get()
    }

    func release(_ list: MovieList) {
        continuations.removeValue(forKey: list)?.resume()
    }

    func hasPendingRequest(_ list: MovieList) -> Bool {
        continuations[list] != nil
    }

    /// Stubs every section's list: section at offset N returns `testMovie(N)`.
    func stubAllLists(window: TrendingWindow = .day) {
        for (offset, section) in HomeSection.allCases.enumerated() {
            let list = section.list(window: window)
            results[list] = .success(MoviePage(page: 1, movies: [testMovie(offset)], totalPages: 1))
        }
    }
}
