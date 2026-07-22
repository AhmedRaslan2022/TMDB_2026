//
//  HomeViewModelConcurrencyTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 18/07/2026.
//

import CoreModels
import Foundation
import Testing
@testable import FeatureHome

/// Concurrency-sensitive Home paths, driven by the gated mock: parallel
/// fan-out, in-flight guards, and fetch preemption.
@MainActor
@Suite("HomeViewModel concurrency")
struct HomeViewModelConcurrencyTests {
    private let useCase = FetchMovieListUseCaseMock()
    private let viewModel: HomeViewModel

    init() throws {
        viewModel = try HomeViewModel(
            fetchMovieList: useCase,
            imageBaseURL: #require(URL(string: "https://img.invalid/t/p"))
        )
    }

    @Test("sections load independently: a slow section doesn't block the others")
    func parallelIndependence() async {
        useCase.stubAllLists()
        useCase.gatedLists = [.trending(.day)]

        let load = Task { await viewModel.load() }
        for _ in 0 ..< 10000 where viewModel.state(for: .popular) != .loaded([testMovie(2)]) {
            await Task.yield()
        }

        // Popular finished while trending is still held open.
        #expect(viewModel.state(for: .popular) == .loaded([testMovie(2)]))
        #expect(viewModel.state(for: .trending) == .loading)

        useCase.release(.trending(.day))
        await load.value
        #expect(viewModel.state(for: .trending) == .loaded([testMovie(0)]))
    }

    @Test("refresh keeps current content on screen until fresh data arrives")
    func refreshKeepsStaleContent() async {
        useCase.stubAllLists()
        await viewModel.load()
        useCase.results[.popular] = .success(MoviePage(page: 1, movies: [testMovie(99)], totalPages: 1))
        useCase.gatedLists = [.popular]

        let refresh = Task { await viewModel.refresh() }
        for _ in 0 ..< 10000 where !useCase.hasPendingRequest(.popular) {
            await Task.yield()
        }
        #expect(viewModel.state(for: .popular) == .loaded([testMovie(2)]), "stale content stays during refresh")

        useCase.release(.popular)
        await refresh.value
        #expect(viewModel.state(for: .popular) == .loaded([testMovie(99)]))
    }

    @Test("a second load while a section is in flight doesn't duplicate its request")
    func reentrancyGuard() async {
        useCase.stubAllLists()
        useCase.gatedLists = [.trending(.day)]

        let first = Task { await viewModel.load() }
        for _ in 0 ..< 10000 where !useCase.requestedLists.contains(.trending(.day)) {
            await Task.yield()
        }

        await viewModel.load()

        #expect(useCase.requestedLists.filter { $0 == .trending(.day) }.count == 1)
        useCase.release(.trending(.day))
        await first.value
    }

    @Test("window toggle during an in-flight trending fetch supersedes it — no desync")
    func windowToggleSupersedesInFlightFetch() async {
        useCase.stubAllLists()
        useCase.stubAllLists(window: .week)
        useCase.gatedLists = [.trending(.day)]

        let load = Task { await viewModel.load() }
        for _ in 0 ..< 10000 where !useCase.hasPendingRequest(.trending(.day)) {
            await Task.yield()
        }

        // Toggle while the day fetch is suspended: must fetch week anyway.
        await viewModel.selectTrendingWindow(.week)
        #expect(viewModel.trendingWindow == .week)
        #expect(viewModel.state(for: .trending) == .loaded([testMovie(0)]))

        // The stale day result must be dropped when it finally lands.
        useCase.release(.trending(.day))
        await load.value
        #expect(viewModel.state(for: .trending) == .loaded([testMovie(0)]), "stale day result must not clobber week")
        #expect(viewModel.trendingWindow == .week)
    }

    @Test("refresh skips sections that are already in flight")
    func refreshSkipsInFlightSections() async {
        useCase.stubAllLists()
        useCase.gatedLists = [.trending(.day)]

        let load = Task { await viewModel.load() }
        for _ in 0 ..< 10000 where !useCase.hasPendingRequest(.trending(.day)) {
            await Task.yield()
        }

        await viewModel.refresh()

        #expect(useCase.requestedLists.filter { $0 == .trending(.day) }.count == 1)
        useCase.release(.trending(.day))
        await load.value
        #expect(viewModel.state(for: .trending) == .loaded([testMovie(0)]))
    }
}
