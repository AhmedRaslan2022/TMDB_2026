//
//  SearchViewModelRecentsTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 19/07/2026.
//

import CoreModels
import Foundation
import Testing
@testable import FeatureSearch

/// Recent-searches integration in the view model.
@MainActor
@Suite("SearchViewModel recents")
struct SearchViewModelRecentsTests {
    private let useCase = SearchUseCaseMock()
    private let recents = RecentSearchesRepositoryMock()
    private let viewModel: SearchViewModel

    init() throws {
        viewModel = try SearchViewModel(
            searchMovies: useCase,
            recentSearches: recents,
            imageBaseURL: #require(URL(string: "https://img.invalid/t/p")),
            debounce: .zero
        )
    }

    @Test("loadRecents surfaces stored queries")
    func loadRecents() async throws {
        try await recents.record("dune")
        try await recents.record("arrival")

        await viewModel.loadRecents()

        #expect(viewModel.recentSearches == ["arrival", "dune"])
    }

    @Test("live typing does NOT record — only an explicit submit does")
    func typingDoesNotRecord() async {
        useCase.stub("dune", ids: 1 ... 3)
        viewModel.query = "dune"
        await waitUntil("results") {
            if case .results = viewModel.state {
                true
            } else {
                false
            }
        }

        #expect(recents.recordedCount == 0, "search-as-you-type must not pollute recents")

        await viewModel.submit()
        #expect(recents.recordedCount == 1)
        #expect(viewModel.recentSearches == ["dune"])
    }

    @Test("submit ignores a blank query")
    func submitBlank() async {
        viewModel.query = "   "
        await viewModel.submit()

        #expect(recents.recordedCount == 0)
    }

    @Test("selecting a recent re-runs it and bumps recency")
    func selectRecent() async throws {
        try await recents.record("dune")
        try await recents.record("arrival")
        await viewModel.loadRecents()
        useCase.stub("dune", ids: 1 ... 3)

        await viewModel.selectRecent("dune")

        #expect(viewModel.query == "dune")
        #expect(viewModel.recentSearches.first == "dune", "re-selected query bumped to front")
        await waitUntil("dune results") {
            if case let .results(content) = viewModel.state {
                content.query == "dune"
            } else {
                false
            }
        }
    }

    @Test("deleting a recent removes it")
    func deleteRecent() async throws {
        try await recents.record("dune")
        try await recents.record("arrival")
        await viewModel.loadRecents()

        await viewModel.deleteRecent("dune")

        #expect(viewModel.recentSearches == ["arrival"])
    }

    @Test("clearing removes all recents")
    func clearRecents() async throws {
        try await recents.record("dune")
        try await recents.record("arrival")
        await viewModel.loadRecents()

        await viewModel.clearRecents()

        #expect(viewModel.recentSearches.isEmpty)
    }
}
