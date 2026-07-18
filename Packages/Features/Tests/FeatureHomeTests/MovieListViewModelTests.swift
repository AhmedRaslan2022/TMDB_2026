//
//  MovieListViewModelTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 18/07/2026.
//

import CoreModels
import Foundation
import Testing
@testable import FeatureHome

@MainActor
@Suite("MovieListViewModel")
struct MovieListViewModelTests {
    /// Page-aware mock: results keyed by page number, with optional per-page
    /// gating so concurrency guards are observable.
    @MainActor
    private final class PagedFetchMock: FetchMovieListUseCase {
        var pages: [Int: Result<MoviePage, Error>] = [:]
        var gatedPages: Set<Int> = []
        private(set) var requests: [(list: MovieList, page: Int)] = []
        private var continuations: [Int: CheckedContinuation<Void, Never>] = [:]

        func execute(list: MovieList, page: Int) async throws -> MoviePage {
            requests.append((list, page))
            if gatedPages.contains(page) {
                if continuations[page] != nil {
                    // A second suspension would leak the first continuation
                    // and hang the suite — fail fast instead.
                    Issue.record("second gated request for page \(page) while one is already suspended")
                } else {
                    await withCheckedContinuation { continuations[page] = $0 }
                }
            }
            guard let result = pages[page] else {
                throw MockError.unstubbed
            }
            return try result.get()
        }

        func release(_ page: Int) {
            continuations.removeValue(forKey: page)?.resume()
        }

        func hasPendingRequest(_ page: Int) -> Bool {
            continuations[page] != nil
        }
    }

    private let useCase = PagedFetchMock()
    private let viewModel: MovieListViewModel

    init() throws {
        viewModel = try MovieListViewModel(
            section: .popular,
            window: .day,
            fetchMovieList: useCase,
            imageBaseURL: #require(URL(string: "https://img.invalid/t/p"))
        )
    }

    private func page(_ number: Int, ids: ClosedRange<Int>, totalPages: Int = 3) -> MoviePage {
        MoviePage(page: number, movies: ids.map(testMovie), totalPages: totalPages)
    }

    private var loadedContent: MovieListViewModel.Content? {
        if case let .loaded(content) = viewModel.state {
            content
        } else {
            nil
        }
    }

    @Test("first page loads into content with pagination flags")
    func firstPageLoads() async throws {
        useCase.pages[1] = .success(page(1, ids: 1 ... 20))

        await viewModel.loadFirstPage()

        let content = try #require(loadedContent)
        #expect(content.movies.count == 20)
        #expect(content.hasMorePages)
        #expect(!content.isLoadingMore)
        #expect(useCase.requests.map(\.page) == [1])
        #expect(useCase.requests.first?.list == .popular)
    }

    @Test("nearing the end appends the next page, deduplicated")
    func loadMoreAppends() async throws {
        useCase.pages[1] = .success(page(1, ids: 1 ... 20))
        // Page 2 repeats movie 20 — a TMDB quirk — and must be deduped.
        useCase.pages[2] = .success(page(2, ids: 20 ... 40))
        await viewModel.loadFirstPage()

        await viewModel.loadMoreIfNeeded(after: testMovie(18))

        let content = try #require(loadedContent)
        #expect(content.movies.count == 40)
        #expect(content.movies.map(\.id) == Array(1 ... 40))
        #expect(content.hasMorePages)
        #expect(useCase.requests.map(\.page) == [1, 2])
    }

    @Test("items far from the end don't trigger a fetch")
    func noFetchFarFromEnd() async {
        useCase.pages[1] = .success(page(1, ids: 1 ... 20))
        await viewModel.loadFirstPage()

        await viewModel.loadMoreIfNeeded(after: testMovie(3))

        #expect(useCase.requests.map(\.page) == [1])
    }

    @Test("the last page turns infinite scroll off")
    func lastPageStopsPagination() async throws {
        useCase.pages[1] = .success(page(1, ids: 1 ... 20, totalPages: 2))
        useCase.pages[2] = .success(page(2, ids: 21 ... 40, totalPages: 2))
        await viewModel.loadFirstPage()
        await viewModel.loadMoreIfNeeded(after: testMovie(20))

        let content = try #require(loadedContent)
        #expect(!content.hasMorePages)

        await viewModel.loadMoreIfNeeded(after: testMovie(40))
        #expect(useCase.requests.map(\.page) == [1, 2], "no fetch beyond the last page")
    }

    @Test("a failed next page keeps content and re-arms the trigger")
    func loadMoreFailureKeepsContent() async throws {
        useCase.pages[1] = .success(page(1, ids: 1 ... 20))
        useCase.pages[2] = .failure(MockError.stubbed)
        await viewModel.loadFirstPage()

        await viewModel.loadMoreIfNeeded(after: testMovie(20))

        var content = try #require(loadedContent)
        #expect(content.movies.count == 20, "failed page must not drop content")
        #expect(!content.isLoadingMore)

        // Scrolling near the end again retries.
        useCase.pages[2] = .success(page(2, ids: 21 ... 40))
        await viewModel.loadMoreIfNeeded(after: testMovie(19))
        content = try #require(loadedContent)
        #expect(content.movies.count == 40)
    }

    @Test("concurrent near-end triggers fetch the next page exactly once")
    func doubleFetchGuard() async throws {
        useCase.pages[1] = .success(page(1, ids: 1 ... 20))
        useCase.pages[2] = .success(page(2, ids: 21 ... 40))
        await viewModel.loadFirstPage()
        useCase.gatedPages = [2]

        let first = Task { await viewModel.loadMoreIfNeeded(after: testMovie(20)) }
        for _ in 0 ..< 10000 where !useCase.hasPendingRequest(2) {
            await Task.yield()
        }

        // A second cell's trigger while page 2 is in flight must be dropped.
        await viewModel.loadMoreIfNeeded(after: testMovie(19))

        #expect(useCase.requests.map(\.page) == [1, 2], "in-flight page must not be fetched twice")
        useCase.release(2)
        await first.value
        #expect(try #require(loadedContent).movies.count == 40)
    }

    @Test("duplicates inside a single page are dropped too")
    func withinPageDedupe() async throws {
        useCase.pages[1] = .success(MoviePage(
            page: 1,
            movies: [testMovie(1), testMovie(2), testMovie(1)],
            totalPages: 1
        ))

        await viewModel.loadFirstPage()

        #expect(try #require(loadedContent).movies.map(\.id) == [1, 2])
    }

    @Test("first-page failure lands in error; loadFirstPage retries out of it")
    func firstPageFailureAndRetry() async throws {
        useCase.pages[1] = .failure(MockError.stubbed)

        await viewModel.loadFirstPage()

        guard case .error = viewModel.state else {
            Issue.record("expected .error, got \(viewModel.state)")
            return
        }

        useCase.pages[1] = .success(page(1, ids: 1 ... 20))
        await viewModel.loadFirstPage()
        #expect(try #require(loadedContent).movies.count == 20)
    }

    @Test("loadFirstPage is idempotent once content is on screen")
    func firstPageIdempotent() async {
        useCase.pages[1] = .success(page(1, ids: 1 ... 20))
        await viewModel.loadFirstPage()

        await viewModel.loadFirstPage()

        #expect(useCase.requests.map(\.page) == [1])
    }

    @Test("cancellation of the first page returns to idle, not error")
    func firstPageCancellation() async {
        useCase.pages[1] = .failure(CancellationError())

        await viewModel.loadFirstPage()

        #expect(viewModel.state == .idle)
    }
}
