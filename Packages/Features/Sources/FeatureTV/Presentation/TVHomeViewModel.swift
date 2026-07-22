//
//  TVHomeViewModel.swift
//  TMDB
//
//  Created by Ahmed Raslan on 21/07/2026.
//

import CoreModels
import CoreUI
import Foundation
import Observation

/// Drives the TV tab: fetches every TV list in parallel with a `TaskGroup`,
/// tracking one `SectionState` per list so a failing section degrades
/// gracefully. The movie twin of `HomeViewModel`, minus the trending window.
@Observable
@MainActor
public final class TVHomeViewModel {
    /// Exhaustive state of one list section.
    public enum SectionState: Equatable {
        case idle
        case loading
        case loaded([MediaItem])
        case error(LocalizedStringResource)
    }

    /// Per-list states. Views read through `state(for:)`.
    public private(set) var sectionStates: [TVList: SectionState]

    private let fetchTVList: any FetchTVListUseCase
    private let imageBaseURL: URL
    /// Lists with a fetch in flight — guards re-entrant fetches.
    private var inFlight: Set<TVList> = []

    public init(fetchTVList: any FetchTVListUseCase, imageBaseURL: URL) {
        self.fetchTVList = fetchTVList
        self.imageBaseURL = imageBaseURL
        sectionStates = Dictionary(uniqueKeysWithValues: TVList.allCases.map { ($0, .idle) })
    }

    /// The w342 poster URL for carousel cards, or `nil` without a poster.
    public func posterURL(for show: MediaItem) -> URL? {
        TMDBImageURL.url(base: imageBaseURL, path: show.posterPath, size: .w342)
    }

    public func state(for list: TVList) -> SectionState {
        sectionStates[list] ?? .idle
    }

    /// Initial load: fetches lists still `.idle`, in parallel. Safe to call on
    /// every re-appearance — resolved sections are left alone.
    public func load() async {
        await fetch(lists: TVList.allCases.filter { state(for: $0) == .idle }, showLoading: true)
    }

    /// Pull-to-refresh: re-fetches all lists, keeping current content until
    /// each fresh page arrives.
    public func refresh() async {
        await fetch(lists: TVList.allCases, showLoading: false)
    }

    /// Re-fetches a single failed list.
    public func retry(list: TVList) async {
        await fetch(lists: [list], showLoading: true)
    }

    private func fetch(lists targets: [TVList], showLoading: Bool) async {
        let lists = targets.filter { !inFlight.contains($0) }
        guard !lists.isEmpty else { return }

        for list in lists {
            inFlight.insert(list)
            if showLoading {
                sectionStates[list] = .loading
            }
        }

        await withTaskGroup(of: (TVList, Result<[MediaItem], any Error>).self) { group in
            for list in lists {
                group.addTask { [fetchTVList] in
                    do {
                        let page = try await fetchTVList.execute(list: list, page: 1)
                        return (list, .success(page.movies))
                    } catch {
                        return (list, .failure(error))
                    }
                }
            }
            for await (list, result) in group {
                apply(result, to: list)
            }
        }
    }

    private func apply(_ result: Result<[MediaItem], any Error>, to list: TVList) {
        inFlight.remove(list)
        switch result {
        case let .success(shows):
            sectionStates[list] = .loaded(shows)
        case .failure(is CancellationError):
            if state(for: list) == .loading {
                sectionStates[list] = .idle
            }
        case .failure:
            sectionStates[list] = .error(LocalizedStringResource(
                moduleKey:
                "tv.section.error",
                defaultValue: "Couldn't load this section.",
                bundle: .module,
                comment: "Shown inside a TV section when its fetch fails"
            ))
        }
    }
}
