//
//  MovieListViewModel.swift
//  TMDB
//
//  Created by Ahmed Raslan on 18/07/2026.
//

import CoreModels
import CoreUI
import Foundation
import Observation

/// Drives a "see all" screen: one movie list, paginated with infinite
/// scroll. The trending window is captured at push time — toggling on Home
/// doesn't retroactively change an already-pushed list.
@Observable
@MainActor
public final class MovieListViewModel {
    /// Loaded-list payload; mutated in place as pages append.
    public struct Content: Equatable {
        public var movies: [Movie]
        public var hasMorePages: Bool
        /// `true` while the next page is being appended (footer spinner).
        public var isLoadingMore: Bool
    }

    /// Exhaustive screen state. Load-more outcomes mutate `loaded`'s content
    /// rather than switching state, so the list never disappears mid-scroll.
    public enum ViewState: Equatable {
        case idle
        case loading
        case loaded(Content)
        case error(LocalizedStringResource)
    }

    public private(set) var state: ViewState = .idle

    /// How close to the end (in items) the user must be to trigger the next
    /// page fetch.
    private static let loadMoreThreshold = 5

    public let section: HomeSection
    private let list: MovieList
    private let fetchMovieList: any FetchMovieListUseCase
    private let imageBaseURL: URL
    private var currentPage = 0

    public init(
        section: HomeSection,
        window: TrendingWindow,
        fetchMovieList: any FetchMovieListUseCase,
        imageBaseURL: URL
    ) {
        self.section = section
        list = section.list(window: window)
        self.fetchMovieList = fetchMovieList
        self.imageBaseURL = imageBaseURL
    }

    /// The w342 poster URL for grid cells, or `nil` without a poster.
    public func posterURL(for movie: Movie) -> URL? {
        TMDBImageURL.url(base: imageBaseURL, path: movie.posterPath, size: .w342)
    }

    /// Loads page 1. Idempotent once content is on screen; callable again
    /// from the error state (retry).
    public func loadFirstPage() async {
        switch state {
        case .loading, .loaded:
            return
        case .idle, .error:
            break
        }
        state = .loading
        do {
            let page = try await fetchMovieList.execute(list: list, page: 1)
            currentPage = page.page
            state = .loaded(Content(
                movies: Self.deduplicated(page.movies, knownIDs: []),
                hasMorePages: page.hasMorePages,
                isLoadingMore: false
            ))
        } catch is CancellationError {
            state = .idle
        } catch {
            state = .error(Self.errorMessage)
        }
    }

    /// Fetches the next page once `movie` is within the last few items.
    /// A failed page keeps current content and stops the footer spinner;
    /// scrolling near the end again re-triggers the fetch.
    public func loadMoreIfNeeded(after movie: Movie) async {
        guard case var .loaded(content) = state,
              content.hasMorePages,
              !content.isLoadingMore,
              content.movies.suffix(Self.loadMoreThreshold).contains(where: { $0.id == movie.id })
        else { return }

        content.isLoadingMore = true
        state = .loaded(content)

        do {
            let page = try await fetchMovieList.execute(list: list, page: currentPage + 1)
            currentPage = page.page
            content.movies += Self.deduplicated(page.movies, knownIDs: Set(content.movies.map(\.id)))
            content.hasMorePages = page.hasMorePages
            content.isLoadingMore = false
            state = .loaded(content)
        } catch {
            content.isLoadingMore = false
            state = .loaded(content)
        }
    }

    /// TMDB occasionally repeats a movie across pages — and, defensively,
    /// within one — so IDs are deduplicated before display: SwiftUI's
    /// `ForEach` traps on colliding identifiers.
    private static func deduplicated(_ movies: [Movie], knownIDs: Set<Int>) -> [Movie] {
        var seen = knownIDs
        return movies.filter { seen.insert($0.id).inserted }
    }

    private static var errorMessage: LocalizedStringResource {
        LocalizedStringResource(
            moduleKey:
            "movieList.error",
            defaultValue: "Couldn't load this list.",
            bundle: .module,
            comment: "Shown when a see-all movie list fails to load"
        )
    }
}
