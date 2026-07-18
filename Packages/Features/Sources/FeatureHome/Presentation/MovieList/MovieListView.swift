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
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case let .error(message):
            errorView(message)
        case let .loaded(content):
            grid(content)
        }
    }

    private func grid(_ content: MovieListViewModel.Content) -> some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 130), spacing: AppSpacing.md, alignment: .top)],
                spacing: AppSpacing.lg
            ) {
                ForEach(content.movies) { movie in
                    MoviePosterCard(
                        movie: movie,
                        posterURL: viewModel.posterURL(for: movie),
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
