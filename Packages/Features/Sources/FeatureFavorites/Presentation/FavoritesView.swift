//
//  FavoritesView.swift
//  TMDB
//
//  Created by Ahmed Raslan on 17/07/2026.
//

import CoreModels
import CoreUI
import SwiftUI

/// The Favorites tab: a poster grid of the user's favorites with pull-to-
/// refresh and per-card removal, backed by the offline-first local store.
/// Navigation intent is reported through `onSelectMovie`.
public struct FavoritesView: View {
    @State private var viewModel: FavoritesViewModel
    private let onSelectMovie: (Int) -> Void

    public init(viewModel: FavoritesViewModel, onSelectMovie: @escaping (Int) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onSelectMovie = onSelectMovie
    }

    public var body: some View {
        content
            .navigationTitle(Text("Favorites", comment: "Favorites tab title"))
            .task { await viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            loadingGrid
        case let .loaded(movies):
            grid(movies)
        case .empty:
            emptyView
        case let .error(message):
            errorView(message)
        }
    }

    private var gridColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 130), spacing: AppSpacing.md, alignment: .top)]
    }

    private func grid(_ movies: [Movie]) -> some View {
        ScrollView {
            LazyVGrid(columns: gridColumns, spacing: AppSpacing.lg) {
                ForEach(movies) { movie in
                    PosterCard(
                        title: movie.title,
                        posterURL: viewModel.posterURL(for: movie),
                        rating: movie.voteCount > 0 ? movie.voteAverage : nil,
                        accessibilityID: "favorites.movie.\(movie.id)",
                        onSelect: { onSelectMovie(movie.id) }
                    )
                    // Grids have no native swipe-to-delete, so removal is a
                    // long-press context action — the grid-idiomatic swipe.
                    .contextMenu {
                        Button(role: .destructive) {
                            Task { await viewModel.remove(movie) }
                        } label: {
                            Label {
                                Text("Remove from Favorites", comment: "Remove a favorite")
                            } icon: {
                                Image(systemName: "heart.slash")
                            }
                        }
                    }
                }
            }
            .padding(AppSpacing.lg)
        }
        .refreshable { await viewModel.refresh() }
    }

    private var loadingGrid: some View {
        ScrollView {
            LazyVGrid(columns: gridColumns, spacing: AppSpacing.lg) {
                ForEach(0 ..< 6) { _ in
                    PosterCardSkeleton()
                }
            }
            .padding(AppSpacing.lg)
        }
        .scrollDisabled(true)
        .shimmering()
        .accessibilityElement()
        .accessibilityLabel(Text("Loading favorites", comment: "VoiceOver label while favorites load"))
    }

    private var emptyView: some View {
        ContentUnavailableView {
            Label {
                Text("No Favorites Yet", comment: "Empty favorites title")
            } icon: {
                Image(systemName: "heart")
            }
        } description: {
            Text("Tap the heart on a movie to keep it here.", comment: "Empty favorites description")
        }
    }

    private func errorView(_ message: LocalizedStringResource) -> some View {
        ContentUnavailableView {
            Label {
                Text("Couldn't Load Favorites", comment: "Favorites error title")
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
            FavoritesView(
                viewModel: FavoritesViewModel(
                    repository: PreviewFavoritesRepository(),
                    imageBaseURL: URL(fileURLWithPath: "/")
                ),
                onSelectMovie: { _ in }
            )
        }
    }

    private struct PreviewFavoritesRepository: FavoritesRepository {
        func favorites() async throws -> [Movie] {
            (1 ... 6).map { Movie(id: $0, title: "Favorite \($0)", overview: "", voteAverage: 8) }
        }

        func isFavorite(movieID _: Int) async throws -> Bool {
            true
        }

        func setFavorite(_: Movie, isFavorite _: Bool) async throws {}
        func synchronize() async throws {}
    }
#endif
