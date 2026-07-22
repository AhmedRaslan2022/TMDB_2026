//
//  TVHomeViewModelTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 21/07/2026.
//

import CoreModels
import Foundation
import Testing
@testable import FeatureTV

@MainActor
@Suite("TVHomeViewModel")
struct TVHomeViewModelTests {
    private enum MockError: Error { case stubbed }

    /// Serves per-list stubbed pages, or a per-list error.
    @MainActor
    private final class FetchMock: FetchTVListUseCase {
        var pages: [TVList: MoviePage] = [:]
        var failing: Set<TVList> = []
        private(set) var requested: [TVList] = []

        func execute(list: TVList, page: Int) async throws -> MoviePage {
            requested.append(list)
            if failing.contains(list) {
                throw MockError.stubbed
            }
            return pages[list] ?? MoviePage(page: page, movies: [], totalPages: 1)
        }
    }

    private let mock = FetchMock()

    private func makeViewModel() throws -> TVHomeViewModel {
        try TVHomeViewModel(fetchTVList: mock, imageBaseURL: #require(URL(string: "https://img.invalid/t/p")))
    }

    private func show(_ id: Int) -> MediaItem {
        MediaItem(id: id, mediaType: .tv, title: "Show \(id)", overview: "")
    }

    @Test("each list lands in .loaded with its shows")
    func loadedStates() async throws {
        mock.pages[.popular] = MoviePage(page: 1, movies: [show(2), show(3)], totalPages: 1)
        let viewModel = try makeViewModel()

        await viewModel.load()

        #expect(viewModel.state(for: .popular) == .loaded([show(2), show(3)]))
        #expect(Set(mock.requested) == Set(TVList.allCases))
    }

    @Test("a failing list degrades to .error while others still load")
    func partialFailure() async throws {
        mock.failing = [.onTheAir]
        mock.pages[.popular] = MoviePage(page: 1, movies: [show(2)], totalPages: 1)
        let viewModel = try makeViewModel()

        await viewModel.load()

        guard case .error = viewModel.state(for: .onTheAir) else {
            Issue.record("expected .error for the failing section")
            return
        }
        #expect(viewModel.state(for: .popular) == .loaded([show(2)]))
    }

    @Test("load is idempotent — resolved sections aren't refetched")
    func loadIdempotent() async throws {
        mock.pages[.popular] = MoviePage(page: 1, movies: [show(2)], totalPages: 1)
        let viewModel = try makeViewModel()
        await viewModel.load()

        await viewModel.load()

        #expect(mock.requested.count == TVList.allCases.count, "no section refetched on a second load")
    }

    @Test("retry re-fetches a single failed list")
    func retrySingle() async throws {
        mock.failing = [.topRated]
        let viewModel = try makeViewModel()
        await viewModel.load()
        mock.failing = []
        mock.pages[.topRated] = MoviePage(page: 1, movies: [show(9)], totalPages: 1)

        await viewModel.retry(list: .topRated)

        #expect(viewModel.state(for: .topRated) == .loaded([show(9)]))
    }
}
