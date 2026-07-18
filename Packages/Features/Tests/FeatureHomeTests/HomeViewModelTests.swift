//
//  HomeViewModelTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 18/07/2026.
//

import CoreModels
import Foundation
import Testing
@testable import FeatureHome

/// Sequential behavior of the Home screen: loading, degradation, toggles and
/// URL composition. Concurrency-sensitive paths live in
/// `HomeViewModelConcurrencyTests`.
@MainActor
@Suite("HomeViewModel")
struct HomeViewModelTests {
    private let useCase = FetchMovieListUseCaseMock()
    private let viewModel: HomeViewModel

    init() throws {
        viewModel = try HomeViewModel(
            fetchMovieList: useCase,
            imageBaseURL: #require(URL(string: "https://img.invalid/t/p"))
        )
    }

    @Test("load fetches all five sections and lands each in its own loaded state")
    func loadAllSections() async {
        useCase.stubAllLists()

        await viewModel.load()

        #expect(Set(useCase.requestedLists) == Set(HomeSection.allCases.map { $0.list(window: .day) }))
        #expect(useCase.requestedLists.count == 5)
        for (offset, section) in HomeSection.allCases.enumerated() {
            #expect(viewModel.state(for: section) == .loaded([testMovie(offset)]))
        }
    }

    @Test("one failing section degrades alone; the rest still load")
    func perSectionFailure() async {
        useCase.stubAllLists()
        useCase.results[.popular] = .failure(MockError.stubbed)

        await viewModel.load()

        guard case .error = viewModel.state(for: .popular) else {
            Issue.record("expected popular to be .error, got \(viewModel.state(for: .popular))")
            return
        }
        for section in HomeSection.allCases where section != .popular {
            guard case .loaded = viewModel.state(for: section) else {
                Issue.record("expected \(section) to be .loaded")
                return
            }
        }
    }

    @Test("load is idempotent once sections resolve — a re-appearing view refetches nothing")
    func loadIdempotentAfterResolution() async {
        useCase.stubAllLists()
        useCase.results[.popular] = .failure(MockError.stubbed)
        await viewModel.load()
        let requestsAfterFirstLoad = useCase.requestedLists.count

        await viewModel.load()

        #expect(useCase.requestedLists.count == requestsAfterFirstLoad, "resolved sections must not refetch")
        guard case .error = viewModel.state(for: .popular) else {
            Issue.record("error section must keep its state (retry owns re-fetching)")
            return
        }
        #expect(viewModel.state(for: .nowPlaying) == .loaded([testMovie(1)]))
    }

    @Test("selectTrendingWindow re-fetches only trending, with the new window")
    func trendingWindowToggle() async {
        useCase.stubAllLists()
        useCase.stubAllLists(window: .week)
        await viewModel.load()
        let requestsAfterLoad = useCase.requestedLists.count

        await viewModel.selectTrendingWindow(.week)

        #expect(viewModel.trendingWindow == .week)
        #expect(useCase.requestedLists.count == requestsAfterLoad + 1)
        #expect(useCase.requestedLists.last == .trending(.week))
    }

    @Test("selecting the already-active window is a no-op")
    func sameWindowNoOp() async {
        useCase.stubAllLists()
        await viewModel.load()
        let requestsAfterLoad = useCase.requestedLists.count

        await viewModel.selectTrendingWindow(.day)

        #expect(useCase.requestedLists.count == requestsAfterLoad)
    }

    @Test("cancellation resets a loading section to idle, not error")
    func cancellationResetsToIdle() async {
        useCase.stubAllLists()
        useCase.results[.upcoming] = .failure(CancellationError())

        await viewModel.load()

        #expect(viewModel.state(for: .upcoming) == .idle)
    }

    @Test("retry re-fetches a single failed section")
    func retrySection() async {
        useCase.stubAllLists()
        useCase.results[.popular] = .failure(MockError.stubbed)
        await viewModel.load()
        useCase.results[.popular] = .success(MoviePage(page: 1, movies: [testMovie(7)], totalPages: 1))
        let requestsAfterLoad = useCase.requestedLists.count

        await viewModel.retry(section: .popular)

        #expect(viewModel.state(for: .popular) == .loaded([testMovie(7)]))
        #expect(useCase.requestedLists.count == requestsAfterLoad + 1)
    }

    @Test("posterURL composes the w342 URL from the image base and poster path")
    func posterURLComposition() {
        let movie = Movie(id: 1, title: "A", overview: "", posterPath: "/poster.jpg")

        #expect(viewModel.posterURL(for: movie)?.absoluteString == "https://img.invalid/t/p/w342/poster.jpg")
    }

    @Test("posterURL is nil when the movie has no poster")
    func posterURLNilWithoutPath() {
        #expect(viewModel.posterURL(for: testMovie(1)) == nil)
    }
}
