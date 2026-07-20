//
//  DiscoverViewModel.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

import CoreModels
import CoreUI
import Foundation
import Observation

/// Drives the advanced-search (Discover) screen: a mutable `DiscoverFilters`
/// over a paginated results grid. Changing any filter cancels the in-flight
/// query and reloads from page 1; scrolling near the end appends pages.
@Observable
@MainActor
public final class DiscoverViewModel {
    /// Loaded results; mutated in place as pages append.
    public struct Content: Equatable {
        public var movies: [Movie]
        /// Last fetched TMDB page — authoritative for pagination.
        public var currentPage: Int
        public var hasMorePages: Bool
        public var isLoadingMore: Bool
    }

    /// Exhaustive screen state.
    public enum ViewState: Equatable {
        case loading
        case loaded(Content)
        case empty
        case error(LocalizedStringResource)
    }

    public private(set) var state: ViewState = .loading
    /// The active filter criteria. Read by the view; mutated via the intent
    /// methods so every change triggers a reload.
    public private(set) var filters = DiscoverFilters()
    /// The genre catalog for the filter picker; empty until `load` resolves it.
    public private(set) var genres: [MovieGenre] = []

    private let discoverMovies: any DiscoverMoviesUseCase
    private let imageBaseURL: URL
    private var discoverTask: Task<Void, Never>?

    public init(discoverMovies: any DiscoverMoviesUseCase, imageBaseURL: URL) {
        self.discoverMovies = discoverMovies
        self.imageBaseURL = imageBaseURL
    }

    /// The selectable years, newest first (current year back through 1950).
    public var availableYears: [Int] {
        let current = Calendar(identifier: .gregorian).component(.year, from: .now)
        return Array(stride(from: current, through: 1950, by: -1))
    }

    /// The selectable minimum-rating thresholds.
    public var availableRatings: [Double] {
        [9, 8, 7, 6, 5]
    }

    /// Loads the genre catalog and the first page of results. Call from the
    /// view's `.task`; idempotent once results exist.
    public func load() async {
        if case .loaded = state {
            return
        }
        if genres.isEmpty {
            // A genre-load failure shouldn't block browsing — the other
            // filters still work, so degrade to an empty genre picker.
            genres = await (try? discoverMovies.genres()) ?? []
        }
        await reload()
    }

    // MARK: Filter intents

    public func toggleGenre(_ id: Int) async {
        if filters.genreIDs.contains(id) {
            filters.genreIDs.remove(id)
        } else {
            filters.genreIDs.insert(id)
        }
        await reload()
    }

    public func setSort(_ sort: MovieSortOption) async {
        guard sort != filters.sort else { return }
        filters.sort = sort
        await reload()
    }

    public func setYear(_ year: Int?) async {
        guard year != filters.year else { return }
        filters.year = year
        await reload()
    }

    public func setMinimumRating(_ rating: Double?) async {
        guard rating != filters.minimumRating else { return }
        filters.minimumRating = rating
        await reload()
    }

    public func clearFilters() async {
        guard filters.isActive else { return }
        filters = DiscoverFilters()
        await reload()
    }

    /// The w342 poster URL for result cells, or `nil` without a poster.
    public func posterURL(for movie: Movie) -> URL? {
        TMDBImageURL.url(base: imageBaseURL, path: movie.posterPath, size: .w342)
    }

    /// Fetches the next result page once `movie` is near the end of the grid.
    public func loadMoreIfNeeded(after movie: Movie) async {
        guard case var .loaded(content) = state,
              content.hasMorePages,
              !content.isLoadingMore,
              content.movies.suffix(5).contains(where: { $0.id == movie.id })
        else { return }

        content.isLoadingMore = true
        state = .loaded(content)
        let snapshot = filters

        do {
            let nextPage = try await discoverMovies.execute(filters: snapshot, page: content.currentPage + 1)
            // A filter change since we started owns the state now.
            guard filters == snapshot, case var .loaded(current) = state else { return }
            var seen = Set(current.movies.map(\.id))
            current.movies += nextPage.movies.filter { seen.insert($0.id).inserted }
            current.currentPage = nextPage.page
            current.hasMorePages = nextPage.hasMorePages
            current.isLoadingMore = false
            state = .loaded(current)
        } catch {
            if filters == snapshot, case var .loaded(current) = state {
                current.isLoadingMore = false
                state = .loaded(current)
            }
        }
    }

    // MARK: Reload

    /// Cancels any in-flight query and reloads page 1 for the current filters.
    private func reload() async {
        discoverTask?.cancel()
        let snapshot = filters
        let task = Task { [weak self] in
            guard let self else { return }
            await runDiscover(snapshot)
        }
        discoverTask = task
        await task.value
    }

    private func runDiscover(_ snapshot: DiscoverFilters) async {
        // Only show the full-screen spinner when there's nothing to keep.
        if case .loaded = state {} else {
            state = .loading
        }
        do {
            let page = try await discoverMovies.execute(filters: snapshot, page: 1)
            guard !Task.isCancelled, filters == snapshot else { return }
            state = page.movies.isEmpty
                ? .empty
                : .loaded(Content(
                    movies: page.movies,
                    currentPage: page.page,
                    hasMorePages: page.hasMorePages,
                    isLoadingMore: false
                ))
        } catch is CancellationError {
            // A newer filter change owns the state.
        } catch {
            guard !Task.isCancelled, filters == snapshot else { return }
            state = .error(LocalizedStringResource(
                "discover.error",
                defaultValue: "Couldn't load results. Try adjusting your filters.",
                comment: "Shown when a Discover request fails"
            ))
        }
    }
}
