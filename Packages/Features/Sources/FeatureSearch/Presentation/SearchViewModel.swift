//
//  SearchViewModel.swift
//  TMDB
//
//  Created by Ahmed Raslan on 19/07/2026.
//

import CoreModels
import CoreUI
import Foundation
import Observation

/// Drives search-as-you-type: keystrokes flow through an `AsyncStream`, a
/// debounce window coalesces them, and starting a new search cancels the
/// previous one — including its in-flight network call (the API client
/// surfaces cancellation as `CancellationError`).
@Observable
@MainActor
public final class SearchViewModel {
    /// Loaded results; mutated in place as pages append.
    public struct Content: Equatable {
        /// The query these results answer.
        public let query: String
        public var movies: [Movie]
        /// Last fetched TMDB page — authoritative for pagination (deduping
        /// makes `movies.count` unusable for page math).
        public var currentPage: Int
        public var hasMorePages: Bool
        public var isLoadingMore: Bool
    }

    /// Exhaustive screen state. `idle` means a blank query — the view shows
    /// recent searches there (4.3/4.4). While a NEW query is in flight, the
    /// previous `results` stay on screen (no flash); `searching` appears
    /// only when there is nothing to keep showing.
    public enum ViewState: Equatable {
        case idle
        case searching
        case results(Content)
        case noResults(query: String)
        case error(LocalizedStringResource)
    }

    public private(set) var state: ViewState = .idle

    /// Recent queries, most-recent-first, shown in the `idle` state.
    public private(set) var recentSearches: [String] = []

    /// Bound to the search field. Every change feeds the debounce stream;
    /// clearing resets to idle immediately (no debounce on the way out).
    public var query: String = "" {
        didSet {
            guard query != oldValue else { return }
            queryContinuation.yield(query)
        }
    }

    private let searchMovies: any SearchMoviesUseCase
    private let recentSearchesRepository: any RecentSearchesRepository
    private let imageBaseURL: URL
    private let debounce: Duration
    private static let recentLimit = 10

    private let queryStream: AsyncStream<String>
    private let queryContinuation: AsyncStream<String>.Continuation
    private var pipelineTask: Task<Void, Never>?
    /// The current debounce+search child. Cancelled by every newer keystroke.
    private var searchTask: Task<Void, Never>?
    /// The trimmed query the current results/search represent, so a no-op
    /// edit (e.g. a trailing space) doesn't discard loaded pages.
    private var activeQuery: String?

    /// - Parameter debounce: Keystroke settling window; tests inject shorter.
    public init(
        searchMovies: any SearchMoviesUseCase,
        recentSearches: any RecentSearchesRepository,
        imageBaseURL: URL,
        debounce: Duration = .milliseconds(300)
    ) {
        self.searchMovies = searchMovies
        recentSearchesRepository = recentSearches
        self.imageBaseURL = imageBaseURL
        self.debounce = debounce
        (queryStream, queryContinuation) = AsyncStream.makeStream(of: String.self)
        startPipeline()
    }

    // MARK: Recent searches

    /// Loads recent searches for the idle state; call from the view's `.task`.
    public func loadRecents() async {
        recentSearches = await (try? recentSearchesRepository.recent(limit: Self.recentLimit)) ?? []
    }

    /// Records the current query as a deliberate search (keyboard submit),
    /// refreshing its recency. Live search-as-you-type does NOT record, so
    /// recents never fill with half-typed queries.
    public func submit() async {
        await record(query)
    }

    /// Re-runs a tapped recent query (via the debounce pipeline) and bumps
    /// its recency.
    public func selectRecent(_ recent: String) async {
        query = recent
        await record(recent)
    }

    /// Removes one recent query.
    public func deleteRecent(_ recent: String) async {
        try? await recentSearchesRepository.delete(recent)
        await loadRecents()
    }

    /// Clears all recent queries.
    public func clearRecents() async {
        try? await recentSearchesRepository.clear()
        await loadRecents()
    }

    private func record(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        try? await recentSearchesRepository.record(trimmed)
        await loadRecents()
    }

    // No deinit needed: deallocating the VM drops the stream continuation,
    // which finishes the stream and ends the pipeline's `for await`; the
    // weak-self debounce child no-ops once the VM is gone.

    /// The w342 poster URL for result cells, or `nil` without a poster.
    public func posterURL(for movie: Movie) -> URL? {
        TMDBImageURL.url(base: imageBaseURL, path: movie.posterPath, size: .w342)
    }

    /// Fetches the next result page once `movie` is near the end of the grid.
    public func loadMoreIfNeeded(after movie: Movie) async {
        guard case var .results(content) = state,
              content.hasMorePages,
              !content.isLoadingMore,
              content.movies.suffix(5).contains(where: { $0.id == movie.id })
        else { return }

        content.isLoadingMore = true
        state = .results(content)

        do {
            let page = try await searchMovies.execute(query: content.query, page: content.currentPage + 1)
            guard case var .results(current) = state, current.query == content.query else { return }
            var seen = Set(current.movies.map(\.id))
            current.movies += page.movies.filter { seen.insert($0.id).inserted }
            current.currentPage = page.page
            current.hasMorePages = page.hasMorePages
            current.isLoadingMore = false
            state = .results(current)
        } catch {
            if case var .results(current) = state, current.query == content.query {
                current.isLoadingMore = false
                state = .results(current)
            }
        }
    }

    // MARK: Pipeline

    private func startPipeline() {
        pipelineTask = Task { [weak self, queryStream] in
            for await text in queryStream {
                guard let self else { return }
                dispatch(text)
            }
        }
    }

    /// Per-keystroke: cancel the previous debounce/search child and either
    /// reset (blank) or start a new debounced search.
    private func dispatch(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            searchTask?.cancel()
            activeQuery = nil
            state = .idle
            return
        }
        // Ignore no-op edits (trailing whitespace, casing-free re-entry) for
        // the query already shown or in flight — pagination and scroll
        // position survive. A retype still retries after an error.
        if trimmed == activeQuery, !isErrored {
            return
        }
        searchTask?.cancel()
        activeQuery = trimmed
        searchTask = Task { [weak self, debounce] in
            try? await Task.sleep(for: debounce)
            guard !Task.isCancelled else { return }
            await self?.search(trimmed)
        }
    }

    private var isErrored: Bool {
        if case .error = state {
            true
        } else {
            false
        }
    }

    private func search(_ trimmed: String) async {
        // Keep existing results on screen while the new query resolves.
        if case .results = state {} else {
            state = .searching
        }
        do {
            let page = try await searchMovies.execute(query: trimmed, page: 1)
            guard !Task.isCancelled else { return }
            state = page.movies.isEmpty
                ? .noResults(query: trimmed)
                : .results(Content(
                    query: trimmed,
                    movies: page.movies,
                    currentPage: page.page,
                    hasMorePages: page.hasMorePages,
                    isLoadingMore: false
                ))
        } catch is CancellationError {
            // Superseded by a newer keystroke — that search owns the state.
        } catch {
            guard !Task.isCancelled else { return }
            state = .error(LocalizedStringResource(
                moduleKey:
                "search.error",
                defaultValue: "Something went wrong. Try searching again.",
                bundle: .module,
                comment: "Shown when a search request fails"
            ))
        }
    }
}
