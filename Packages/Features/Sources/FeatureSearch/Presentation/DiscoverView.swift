//
//  DiscoverView.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

import CoreModels
import CoreUI
import SwiftUI

/// The advanced-search screen: a filter bar over a paginated results grid.
/// Navigation intent is reported through `onSelectMovie` — the coordinator
/// decides what happens.
public struct DiscoverView: View {
    @State private var viewModel: DiscoverViewModel
    private let onSelectMovie: (Int) -> Void

    public init(viewModel: DiscoverViewModel, onSelectMovie: @escaping (Int) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onSelectMovie = onSelectMovie
    }

    public var body: some View {
        VStack(spacing: 0) {
            DiscoverFilterBar(
                genres: viewModel.genres,
                filters: viewModel.filters,
                availableYears: viewModel.availableYears,
                availableRatings: viewModel.availableRatings,
                onToggleGenre: { id in Task { await viewModel.toggleGenre(id) } },
                onSetSort: { sort in Task { await viewModel.setSort(sort) } },
                onSetYear: { year in Task { await viewModel.setYear(year) } },
                onSetRating: { rating in Task { await viewModel.setMinimumRating(rating) } },
                onClear: { Task { await viewModel.clearFilters() } }
            )
            Divider()
            content
        }
        .navigationTitle(Text("Discover", bundle: .module, comment: "Advanced-search screen title"))
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
            .task { await viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            loadingGrid
        case let .loaded(content):
            resultsGrid(content)
        case .empty:
            emptyView
        case let .error(message):
            errorView(message)
        }
    }

    private var gridColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 130), spacing: AppSpacing.md, alignment: .top)]
    }

    private func resultsGrid(_ content: DiscoverViewModel.Content) -> some View {
        ScrollView {
            LazyVGrid(columns: gridColumns, spacing: AppSpacing.lg) {
                ForEach(content.movies) { movie in
                    PosterCard(
                        title: movie.title,
                        posterURL: viewModel.posterURL(for: movie),
                        rating: movie.voteCount > 0 ? movie.voteAverage : nil,
                        accessibilityID: "discover.movie.\(movie.id)",
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
        .accessibilityLabel(Text("Loading results", bundle: .module, comment: "VoiceOver label while Discover loads"))
    }

    private var emptyView: some View {
        ContentUnavailableView {
            Label {
                Text("No Matches", bundle: .module, comment: "Discover empty-results title")
            } icon: {
                Image(systemName: "movieclapper")
            }
        } description: {
            Text("No movies match these filters. Try loosening them.", bundle: .module, comment: "Discover empty-results hint")
        }
    }

    private func errorView(_ message: LocalizedStringResource) -> some View {
        ContentUnavailableView {
            Label {
                Text("Couldn't Load", bundle: .module, comment: "Discover error title")
            } icon: {
                Image(systemName: "exclamationmark.triangle")
            }
        } description: {
            Text(message)
        }
    }
}
