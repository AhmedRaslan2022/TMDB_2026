//
//  HomeViewModel.swift
//  TMDB
//
//  Created by Ahmed Raslan on 18/07/2026.
//

import CoreModels
import CoreUI
import Foundation
import Observation

/// Drives the Home screen: fetches all sections in parallel with a
/// `TaskGroup` and tracks one `ViewState` per section, so a failing section
/// degrades gracefully instead of taking the whole screen down.
@Observable
@MainActor
public final class HomeViewModel {
    /// Exhaustive state of one section.
    public enum SectionState: Equatable {
        case idle
        case loading
        case loaded([Movie])
        /// The fetch failed; message is user-facing. Content from a previous
        /// success is intentionally dropped — retry re-fetches.
        case error(LocalizedStringResource)
    }

    /// Per-section states. Views read through `state(for:)`.
    public private(set) var sectionStates: [HomeSection: SectionState]
    /// The window the trending section is showing. Change via
    /// `selectTrendingWindow`.
    public private(set) var trendingWindow: TrendingWindow = .day

    private let fetchMovieList: any FetchMovieListUseCase
    private let imageBaseURL: URL
    /// Sections with a fetch in flight. Guards every non-preempting fetch —
    /// including refresh, whose sections never show `.loading`.
    private var inFlight: Set<HomeSection> = []
    /// Monotonic per-section fetch generation. A child's result is applied
    /// only if its generation is still current, so a preempting fetch (window
    /// toggle) makes any in-flight result stale instead of racing it.
    private var generations: [HomeSection: Int] = [:]

    /// - Parameter imageBaseURL: TMDB image root (e.g. `…/t/p`) from the
    ///   environment; the VM composes per-size URLs so views stay dumb.
    public init(fetchMovieList: any FetchMovieListUseCase, imageBaseURL: URL) {
        self.fetchMovieList = fetchMovieList
        self.imageBaseURL = imageBaseURL
        sectionStates = Dictionary(uniqueKeysWithValues: HomeSection.allCases.map { ($0, .idle) })
    }

    /// The w342 poster URL for carousel cards, or `nil` without a poster.
    public func posterURL(for movie: Movie) -> URL? {
        TMDBImageURL.url(base: imageBaseURL, path: movie.posterPath, size: .w342)
    }

    public func state(for section: HomeSection) -> SectionState {
        sectionStates[section] ?? .idle
    }

    /// Initial load: fetches sections still untouched (`.idle`), in parallel,
    /// with loading placeholders. Safe to call from `.task` on every
    /// re-appearance — resolved sections (loaded or error) are left alone, so
    /// popping back from details never collapses the screen into spinners.
    /// Freshness comes from `refresh()`; failed sections from `retry`.
    public func load() async {
        await fetch(sections: HomeSection.allCases.filter { state(for: $0) == .idle }, showLoading: true)
    }

    /// Pull-to-refresh: re-fetches everything but keeps current content on
    /// screen until each section's fresh page arrives.
    public func refresh() async {
        await fetch(sections: HomeSection.allCases, showLoading: false)
    }

    /// Re-fetches a single failed section.
    public func retry(section: HomeSection) async {
        await fetch(sections: [section], showLoading: true)
    }

    /// Switches the trending window and re-fetches that section, preempting
    /// any in-flight trending fetch — the new window's result supersedes it.
    public func selectTrendingWindow(_ window: TrendingWindow) async {
        guard window != trendingWindow else { return }
        trendingWindow = window
        await fetch(sections: [.trending], showLoading: true, preempting: true)
    }

    private func fetch(sections targets: [HomeSection], showLoading: Bool, preempting: Bool = false) async {
        // Re-entrancy guard: a section already being fetched is left to the
        // fetch that started it — its data is already fresh-in-flight. A
        // preempting fetch instead supersedes it via the generation bump.
        let sections = preempting ? targets : targets.filter { !inFlight.contains($0) }
        guard !sections.isEmpty else { return }

        let window = trendingWindow
        var started: [(section: HomeSection, generation: Int)] = []
        for section in sections {
            let generation = (generations[section] ?? 0) + 1
            generations[section] = generation
            inFlight.insert(section)
            if showLoading {
                sectionStates[section] = .loading
            }
            started.append((section, generation))
        }

        await withTaskGroup(of: (HomeSection, Int, Result<[Movie], any Error>).self) { group in
            for (section, generation) in started {
                let list = section.list(window: window)
                group.addTask { [fetchMovieList] in
                    do {
                        let page = try await fetchMovieList.execute(list: list, page: 1)
                        return (section, generation, .success(page.movies))
                    } catch {
                        return (section, generation, .failure(error))
                    }
                }
            }

            // States update as each child finishes — fast sections render
            // without waiting for slow ones.
            for await (section, generation, result) in group {
                apply(result, to: section, generation: generation)
            }
        }
    }

    private func apply(_ result: Result<[Movie], any Error>, to section: HomeSection, generation: Int) {
        // A superseded fetch's result is stale — drop it. The superseding
        // fetch owns the section's in-flight marker and final state.
        guard generations[section] == generation else { return }
        inFlight.remove(section)

        switch result {
        case let .success(movies):
            sectionStates[section] = .loaded(movies)
        case .failure(is CancellationError):
            // The screen went away mid-fetch; don't surface an error. Reset
            // a loading placeholder so a revisit starts clean.
            if state(for: section) == .loading {
                sectionStates[section] = .idle
            }
        case let .failure(error):
            sectionStates[section] = .error(Self.message(for: error))
        }
    }

    private static func message(for _: any Error) -> LocalizedStringResource {
        LocalizedStringResource(
            moduleKey:
            "home.section.error",
            defaultValue: "Couldn't load this section.",
            bundle: .module,
            comment: "Shown inside a home section when its fetch fails"
        )
    }
}
