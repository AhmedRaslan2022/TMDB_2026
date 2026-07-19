//
//  SearchViewModelTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 19/07/2026.
//

import CoreModels
import Foundation
import Testing
@testable import FeatureSearch

/// Debounce pipeline and state behavior. Pagination lives in
/// `SearchViewModelPaginationTests`.
@MainActor
@Suite("SearchViewModel")
struct SearchViewModelTests {
    private let useCase = SearchUseCaseMock()

    private func makeViewModel(debounce: Duration = .zero) throws -> SearchViewModel {
        try SearchViewModel(
            searchMovies: useCase,
            imageBaseURL: #require(URL(string: "https://img.invalid/t/p")),
            debounce: debounce
        )
    }

    @Test("rapid keystrokes coalesce into one search for the settled query")
    func debounceCoalesces() async throws {
        // Generous window so a loaded CI MainActor can't split the three
        // buffered keystrokes across separate debounce cycles.
        let viewModel = try makeViewModel(debounce: .milliseconds(200))
        useCase.stub("dune", ids: 1 ... 3)

        viewModel.query = "d"
        viewModel.query = "du"
        viewModel.query = "dune"

        await waitUntil("results") {
            if case .results = viewModel.state {
                true
            } else {
                false
            }
        }
        #expect(useCase.requests.map(\.query) == ["dune"])
    }

    @Test("clearing the query resets to idle without searching")
    func clearResetsToIdle() async throws {
        let viewModel = try makeViewModel()
        useCase.stub("dune", ids: 1 ... 3)
        viewModel.query = "dune"
        await waitUntil("results") {
            if case .results = viewModel.state {
                true
            } else {
                false
            }
        }

        viewModel.query = ""

        await waitUntil("idle") { viewModel.state == .idle }
        #expect(useCase.requests.count == 1)
    }

    @Test("whitespace-only queries never hit the use case")
    func blankNeverSearches() async throws {
        let viewModel = try makeViewModel()

        viewModel.query = "   "

        await waitUntil("idle") { viewModel.state == .idle }
        #expect(useCase.requests.isEmpty)
    }

    @Test("a newer keystroke's search supersedes an in-flight one — stale results dropped")
    func staleSearchDropped() async throws {
        let viewModel = try makeViewModel()
        useCase.gate("first")
        useCase.stub("first", ids: 1 ... 5)
        useCase.stub("second", ids: 10 ... 15)

        viewModel.query = "first"
        await waitUntil("first in flight") { useCase.hasPending("first") }

        viewModel.query = "second"
        await waitUntil("second's results") {
            if case let .results(content) = viewModel.state {
                content.query == "second"
            } else {
                false
            }
        }

        useCase.release("first")
        try await Task.sleep(for: .milliseconds(30))
        guard case let .results(content) = viewModel.state else {
            Issue.record("expected results, got \(viewModel.state)")
            return
        }
        #expect(content.query == "second", "released stale search must not clobber the newer one")
    }

    @Test("existing results stay on screen while a new query is in flight")
    func resultsKeptDuringNewSearch() async throws {
        let viewModel = try makeViewModel()
        useCase.stub("dune", ids: 1 ... 5)
        viewModel.query = "dune"
        await waitUntil("dune results") {
            if case .results = viewModel.state {
                true
            } else {
                false
            }
        }

        useCase.gate("blade")
        useCase.stub("blade", ids: 20 ... 25)
        viewModel.query = "blade"
        await waitUntil("blade in flight") { useCase.hasPending("blade") }

        guard case let .results(content) = viewModel.state else {
            Issue.record("expected dune results to remain, got \(viewModel.state)")
            useCase.release("blade")
            return
        }
        #expect(content.query == "dune", "no flash to searching while content exists")

        useCase.release("blade")
        await waitUntil("blade results") {
            if case let .results(content) = viewModel.state {
                content.query == "blade"
            } else {
                false
            }
        }
    }

    @Test("zero hits land in noResults carrying the query")
    func noResults() async throws {
        let viewModel = try makeViewModel()
        useCase.stubEmpty("zzz")

        viewModel.query = "zzz"

        await waitUntil("noResults") { viewModel.state == .noResults(query: "zzz") }
    }

    @Test("a failed search lands in error")
    func errorState() async throws {
        let viewModel = try makeViewModel()

        viewModel.query = "doomed"

        await waitUntil("error") {
            if case .error = viewModel.state {
                true
            } else {
                false
            }
        }
    }
}
