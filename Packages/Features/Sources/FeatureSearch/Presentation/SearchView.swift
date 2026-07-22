//
//  SearchView.swift
//  TMDB
//
//  Created by Ahmed Raslan on 17/07/2026.
//

import CoreModels
import CoreUI
import SwiftUI

/// The Search tab: debounced search-as-you-type over a results grid, with
/// recent searches in the idle state. Navigation intent is reported through
/// `onSelectMovie` — the coordinator decides what happens.
public struct SearchView: View {
    @State private var viewModel: SearchViewModel
    private let onSelectMovie: (Int) -> Void
    private let onOpenDiscover: () -> Void

    public init(
        viewModel: SearchViewModel,
        onSelectMovie: @escaping (Int) -> Void,
        onOpenDiscover: @escaping () -> Void
    ) {
        _viewModel = State(initialValue: viewModel)
        self.onSelectMovie = onSelectMovie
        self.onOpenDiscover = onOpenDiscover
    }

    public var body: some View {
        content
            .navigationTitle(Text("Search", bundle: .module, comment: "Search tab title"))
            .searchable(
                text: $viewModel.query,
                placement: searchPlacement,
                prompt: Text("Search movies", bundle: .module, comment: "Search field prompt")
            )
            .onSubmit(of: .search) {
                Task { await viewModel.submit() }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: onOpenDiscover) {
                        Label {
                            Text("Filters", bundle: .module, comment: "Opens the advanced-search filters screen")
                        } icon: {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                        }
                    }
                    .accessibilityIdentifier("search.discover")
                }
            }
            .task { await viewModel.loadRecents() }
    }

    private var searchPlacement: SearchFieldPlacement {
        #if os(iOS)
            .navigationBarDrawer(displayMode: .always)
        #else
            .automatic
        #endif
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            RecentSearchesView(
                recents: viewModel.recentSearches,
                onSelect: { query in Task { await viewModel.selectRecent(query) } },
                onDelete: { query in Task { await viewModel.deleteRecent(query) } },
                onClear: { Task { await viewModel.clearRecents() } }
            )
        case .searching:
            loadingGrid
        case let .results(content):
            resultsGrid(content)
        case let .noResults(query):
            ContentUnavailableView.search(text: query)
        case let .error(message):
            errorView(message)
        }
    }

    private var gridColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 130), spacing: AppSpacing.md, alignment: .top)]
    }

    private func resultsGrid(_ content: SearchViewModel.Content) -> some View {
        ScrollView {
            LazyVGrid(columns: gridColumns, spacing: AppSpacing.lg) {
                ForEach(content.movies) { movie in
                    PosterCard(
                        title: movie.title,
                        posterURL: viewModel.posterURL(for: movie),
                        rating: movie.voteCount > 0 ? movie.voteAverage : nil,
                        accessibilityID: "search.movie.\(movie.id)",
                        onSelect: { onSelectMovie(movie.id) }
                    )
                    .task { await viewModel.loadMoreIfNeeded(after: movie) }
                }
            }
            .padding(AppSpacing.lg)

            if content.isLoadingMore {
                ProgressView()
                    .padding(.bottom, AppSpacing.xl)
            }
        }
    }

    private var loadingGrid: some View {
        ScrollView {
            LazyVGrid(columns: gridColumns, spacing: AppSpacing.lg) {
                ForEach(0 ..< 9) { _ in
                    PosterCardSkeleton()
                }
            }
            .padding(AppSpacing.lg)
        }
        .scrollDisabled(true)
        .shimmering()
        .accessibilityElement()
        .accessibilityLabel(Text("Searching", bundle: .module, comment: "VoiceOver label while a search runs"))
    }

    private func errorView(_ message: LocalizedStringResource) -> some View {
        ContentUnavailableView {
            Label {
                Text("Search Failed", bundle: .module, comment: "Search error title")
            } icon: {
                Image(systemName: "exclamationmark.triangle")
            }
        } description: {
            Text(message)
        }
    }
}

#if DEBUG
    #Preview {
        NavigationStack {
            SearchView(
                viewModel: SearchViewModel(
                    searchMovies: PreviewSearchUseCase(),
                    recentSearches: PreviewRecentsRepository(),
                    imageBaseURL: URL(fileURLWithPath: "/")
                ),
                onSelectMovie: { _ in },
                onOpenDiscover: {}
            )
        }
    }

    private struct PreviewSearchUseCase: SearchMoviesUseCase {
        func execute(query: String, page: Int) async throws -> MoviePage {
            MoviePage(
                page: page,
                movies: (1 ... 6).map { Movie(id: $0, title: "\(query) \($0)", overview: "", voteAverage: 7) },
                totalPages: 1
            )
        }
    }

    private struct PreviewRecentsRepository: RecentSearchesRepository {
        func recent(limit _: Int) async throws -> [String] {
            ["dune", "arrival"]
        }

        func record(_: String) async throws {}
        func delete(_: String) async throws {}
        func clear() async throws {}
    }
#endif
