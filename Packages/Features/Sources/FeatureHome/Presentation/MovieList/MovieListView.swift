//
//  MovieListView.swift
//  TMDB
//
//  Created by Ahmed Raslan on 18/07/2026.
//

import CoreModels
import CoreUI
import SwiftUI

/// A "see all" screen: poster grid over one paginated movie list, fetching
/// the next page as the user nears the end.
public struct MovieListView: View {
    @State private var viewModel: MovieListViewModel
    private let onSelectMovie: (Int) -> Void

    /// The view model is moved into `@State` so repeated destination-builder
    /// evaluations for the same push reuse one instance.
    public init(viewModel: MovieListViewModel, onSelectMovie: @escaping (Int) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onSelectMovie = onSelectMovie
    }

    public var body: some View {
        content
            .navigationTitle(Text(viewModel.section.title))
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
            .task { await viewModel.loadFirstPage() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            loadingGrid
        case let .error(message):
            errorView(message)
        case let .loaded(content) where content.movies.isEmpty:
            emptyView
        case let .loaded(content):
            grid(content)
        }
    }

    /// Skeleton grid mirroring the loaded layout. The skeletons themselves
    /// are collapsed into one "Loading" element so VoiceOver announces the
    /// screen is busy instead of placeholder noise (or nothing at all).
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
        .accessibilityLabel(Text("Loading", comment: "VoiceOver label while a movie list loads"))
    }

    private var emptyView: some View {
        ContentUnavailableView(
            label: {
                Label {
                    Text("No Movies", comment: "Empty see-all list title")
                } icon: {
                    Image(systemName: "film.stack")
                }
            },
            description: {
                Text("This list has nothing in it right now.", comment: "Empty see-all list description")
            }
        )
    }

    private var gridColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 130), spacing: AppSpacing.md, alignment: .top)]
    }

    private func grid(_ content: MovieListViewModel.Content) -> some View {
        ScrollView {
            LazyVGrid(columns: gridColumns, spacing: AppSpacing.lg) {
                ForEach(content.movies) { movie in
                    PosterCard(
                        title: movie.title,
                        posterURL: viewModel.posterURL(for: movie),
                        rating: movie.voteCount > 0 ? movie.voteAverage : nil,
                        accessibilityID: "home.movie.\(movie.id)",
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

    private func errorView(_ message: LocalizedStringResource) -> some View {
        VStack(spacing: AppSpacing.md) {
            Text(message)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textSecondary)
            Button {
                Task { await viewModel.loadFirstPage() }
            } label: {
                Text("Retry", comment: "Retry loading a see-all movie list")
                    .font(AppTypography.label)
            }
            .buttonStyle(.bordered)
            .tint(AppColors.brandSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
