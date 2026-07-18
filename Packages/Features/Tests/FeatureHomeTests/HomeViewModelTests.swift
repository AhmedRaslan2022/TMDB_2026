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

@MainActor
@Suite("HomeViewModel")
struct HomeViewModelTests {
    private enum MockError: Error, Equatable {
        case unstubbed
        case stubbed
    }

    /// Per-list results and per-list gating, so tests can hold one section
    /// in flight while others complete — proving the fan-out is parallel.
    @MainActor
    private final class FetchMovieListUseCaseMock: FetchMovieListUseCase {
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
    }

    private let useCase = FetchMovieListUseCaseMock()
    private let viewModel: HomeViewModel

    init() {
        viewModel = HomeViewModel(fetchMovieList: useCase)
    }

    private func movie(_ id: Int) -> Movie {
        Movie(id: id, title: "Movie \(id)", overview: "")
    }

    private func stubAllLists(window: TrendingWindow = .day) {
        for (offset, section) in HomeSection.allCases.enumerated() {
            let list = section.list(window: window)
            useCase.results[list] = .success(MoviePage(page: 1, movies: [movie(offset)], totalPages: 1))
        }
    }

    @Test("load fetches all five sections and lands each in its own loaded state")
    func loadAllSections() async {
        stubAllLists()

        await viewModel.load()

        #expect(Set(useCase.requestedLists) == Set(HomeSection.allCases.map { $0.list(window: .day) }))
        #expect(useCase.requestedLists.count == 5)
        for (offset, section) in HomeSection.allCases.enumerated() {
            #expect(viewModel.state(for: section) == .loaded([movie(offset)]))
        }
    }

    @Test("one failing section degrades alone; the rest still load")
    func perSectionFailure() async {
        stubAllLists()
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

    @Test("sections load independently: a slow section doesn't block the others")
    func parallelIndependence() async {
        stubAllLists()
        useCase.gatedLists = [.trending(.day)]

        let load = Task { await viewModel.load() }
        for _ in 0 ..< 10000 where viewModel.state(for: .popular) != .loaded([movie(2)]) {
            await Task.yield()
        }

        // Popular finished while trending is still held open.
        #expect(viewModel.state(for: .popular) == .loaded([movie(2)]))
        #expect(viewModel.state(for: .trending) == .loading)

        useCase.release(.trending(.day))
        await load.value
        #expect(viewModel.state(for: .trending) == .loaded([movie(0)]))
    }

    @Test("selectTrendingWindow re-fetches only trending, with the new window")
    func trendingWindowToggle() async {
        stubAllLists()
        stubAllLists(window: .week)
        await viewModel.load()
        let requestsAfterLoad = useCase.requestedLists.count

        await viewModel.selectTrendingWindow(.week)

        #expect(viewModel.trendingWindow == .week)
        #expect(useCase.requestedLists.count == requestsAfterLoad + 1)
        #expect(useCase.requestedLists.last == .trending(.week))
    }

    @Test("selecting the already-active window is a no-op")
    func sameWindowNoOp() async {
        stubAllLists()
        await viewModel.load()
        let requestsAfterLoad = useCase.requestedLists.count

        await viewModel.selectTrendingWindow(.day)

        #expect(useCase.requestedLists.count == requestsAfterLoad)
    }

    @Test("refresh keeps current content on screen until fresh data arrives")
    func refreshKeepsStaleContent() async {
        stubAllLists()
        await viewModel.load()
        useCase.results[.popular] = .success(MoviePage(page: 1, movies: [movie(99)], totalPages: 1))
        useCase.gatedLists = [.popular]

        let refresh = Task { await viewModel.refresh() }
        for _ in 0 ..< 10000 where !useCase.hasPendingRequest(.popular) {
            await Task.yield()
        }
        #expect(viewModel.state(for: .popular) == .loaded([movie(2)]), "stale content stays during refresh")

        useCase.release(.popular)
        await refresh.value
        #expect(viewModel.state(for: .popular) == .loaded([movie(99)]))
    }

    @Test("a second load while a section is in flight doesn't duplicate its request")
    func reentrancyGuard() async {
        stubAllLists()
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
        stubAllLists()
        stubAllLists(window: .week)
        useCase.gatedLists = [.trending(.day)]

        let load = Task { await viewModel.load() }
        for _ in 0 ..< 10000 where !useCase.hasPendingRequest(.trending(.day)) {
            await Task.yield()
        }

        // Toggle while the day fetch is suspended: must fetch week anyway.
        await viewModel.selectTrendingWindow(.week)
        #expect(viewModel.trendingWindow == .week)
        #expect(viewModel.state(for: .trending) == .loaded([movie(0)]))

        // The stale day result must be dropped when it finally lands.
        useCase.release(.trending(.day))
        await load.value
        #expect(viewModel.state(for: .trending) == .loaded([movie(0)]), "stale day result must not clobber week")
        #expect(viewModel.trendingWindow == .week)
    }

    @Test("refresh skips sections that are already in flight")
    func refreshSkipsInFlightSections() async {
        stubAllLists()
        useCase.gatedLists = [.trending(.day)]

        let load = Task { await viewModel.load() }
        for _ in 0 ..< 10000 where !useCase.hasPendingRequest(.trending(.day)) {
            await Task.yield()
        }

        await viewModel.refresh()

        #expect(useCase.requestedLists.filter { $0 == .trending(.day) }.count == 1)
        useCase.release(.trending(.day))
        await load.value
        #expect(viewModel.state(for: .trending) == .loaded([movie(0)]))
    }

    @Test("cancellation resets a loading section to idle, not error")
    func cancellationResetsToIdle() async {
        stubAllLists()
        useCase.results[.upcoming] = .failure(CancellationError())

        await viewModel.load()

        #expect(viewModel.state(for: .upcoming) == .idle)
    }

    @Test("retry re-fetches a single failed section")
    func retrySection() async {
        stubAllLists()
        useCase.results[.popular] = .failure(MockError.stubbed)
        await viewModel.load()
        useCase.results[.popular] = .success(MoviePage(page: 1, movies: [movie(7)], totalPages: 1))
        let requestsAfterLoad = useCase.requestedLists.count

        await viewModel.retry(section: .popular)

        #expect(viewModel.state(for: .popular) == .loaded([movie(7)]))
        #expect(useCase.requestedLists.count == requestsAfterLoad + 1)
    }
}
