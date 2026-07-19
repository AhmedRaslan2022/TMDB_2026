//
//  SearchViewModelPaginationTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 19/07/2026.
//

import CoreModels
import Foundation
import Testing
@testable import FeatureSearch

/// Infinite scroll over search results.
@MainActor
@Suite("SearchViewModel pagination")
struct SearchViewModelPaginationTests {
    private let useCase = SearchUseCaseMock()
    private let viewModel: SearchViewModel

    init() throws {
        viewModel = try SearchViewModel(
            searchMovies: useCase,
            imageBaseURL: #require(URL(string: "https://img.invalid/t/p")),
            debounce: .zero
        )
    }

    private func loadDune() async {
        useCase.stub("dune", ids: 1 ... 20, totalPages: 3)
        viewModel.query = "dune"
        await waitUntil("dune results") {
            if case .results = viewModel.state {
                true
            } else {
                false
            }
        }
    }

    @Test("load more appends the next page, deduped, tracking the page number")
    func loadMoreAppends() async {
        await loadDune()
        useCase.stub("dune", page: 2, ids: 20 ... 40, totalPages: 3)

        await viewModel.loadMoreIfNeeded(after: searchTestMovie(19))

        guard case let .results(content) = viewModel.state else {
            Issue.record("expected results, got \(viewModel.state)")
            return
        }
        #expect(content.movies.map(\.id) == Array(1 ... 40), "deduped append")
        #expect(content.currentPage == 2)
        #expect(useCase.requests.last?.page == 2)
    }

    @Test("items far from the end don't trigger a page fetch")
    func loadMoreFarFromEnd() async {
        await loadDune()
        let requestCount = useCase.requests.count

        await viewModel.loadMoreIfNeeded(after: searchTestMovie(2))

        #expect(useCase.requests.count == requestCount)
    }

    @Test("a no-op edit (trailing whitespace) keeps loaded pages instead of resetting")
    func trailingWhitespaceKeepsPages() async {
        await loadDune()
        useCase.stub("dune", page: 2, ids: 21 ... 40, totalPages: 3)
        await viewModel.loadMoreIfNeeded(after: searchTestMovie(19))
        let requestsAfterPage2 = useCase.requests.count

        viewModel.query = "dune " // same trimmed query, extra space
        // No new search should fire; give any errant one a chance to run.
        try? await Task.sleep(for: .milliseconds(30))

        #expect(useCase.requests.count == requestsAfterPage2, "no-op edit must not re-search")
        guard case let .results(content) = viewModel.state else {
            Issue.record("expected results, got \(viewModel.state)")
            return
        }
        #expect(content.movies.count == 40, "loaded pages must survive")
        #expect(content.currentPage == 2)
    }

    @Test("a load-more landing after the query changed is dropped")
    func staleLoadMoreDropped() async {
        await loadDune()
        useCase.gate("dune", page: 2)
        useCase.stub("dune", page: 2, ids: 21 ... 40, totalPages: 3)
        useCase.stub("blade", ids: 100 ... 105)

        let loadMore = Task { await viewModel.loadMoreIfNeeded(after: searchTestMovie(19)) }
        await waitUntil("page 2 in flight") { useCase.hasPending("dune", page: 2) }

        viewModel.query = "blade"
        await waitUntil("blade results") {
            if case let .results(content) = viewModel.state {
                content.query == "blade"
            } else {
                false
            }
        }

        useCase.release("dune", page: 2)
        await loadMore.value

        guard case let .results(content) = viewModel.state else {
            Issue.record("expected results, got \(viewModel.state)")
            return
        }
        #expect(content.query == "blade")
        #expect(content.movies.map(\.id) == Array(100 ... 105), "stale page must not merge into new results")
    }
}
