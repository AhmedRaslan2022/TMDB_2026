//
//  HomeView.swift
//  TMDB
//
//  Created by Ahmed Raslan on 17/07/2026.
//

import CoreModels
import CoreUI
import SwiftUI

/// The Home tab: five sections fetched in parallel, each rendered from its
/// own state. Navigation intent is reported through `onSelectMovie` — the
/// coordinator decides what happens.
public struct HomeView: View {
    private let viewModel: HomeViewModel
    private let onSelectMovie: (Int) -> Void
    private let onSeeAll: (HomeSection, TrendingWindow) -> Void

    public init(
        viewModel: HomeViewModel,
        onSelectMovie: @escaping (Int) -> Void,
        onSeeAll: @escaping (HomeSection, TrendingWindow) -> Void
    ) {
        self.viewModel = viewModel
        self.onSelectMovie = onSelectMovie
        self.onSeeAll = onSeeAll
    }

    public var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: AppSpacing.xl) {
                ForEach(HomeSection.allCases) { section in
                    HomeSectionView(
                        section: section,
                        state: viewModel.state(for: section),
                        trendingWindow: viewModel.trendingWindow,
                        posterURL: viewModel.posterURL(for:),
                        onSelectMovie: onSelectMovie,
                        onSelectWindow: { window in
                            Task { await viewModel.selectTrendingWindow(window) }
                        },
                        onSeeAll: { onSeeAll(section, viewModel.trendingWindow) },
                        onRetry: {
                            Task { await viewModel.retry(section: section) }
                        }
                    )
                }
            }
            .padding(.vertical, AppSpacing.lg)
        }
        .navigationTitle(Text("Home", comment: "Home tab title"))
        .refreshable { await viewModel.refresh() }
        .task { await viewModel.load() }
    }
}

#if DEBUG
    #Preview {
        NavigationStack {
            HomeView(
                viewModel: HomeViewModel(
                    fetchMovieList: PreviewFetchMovieListUseCase(),
                    imageBaseURL: URL(fileURLWithPath: "/")
                ),
                onSelectMovie: { _ in },
                onSeeAll: { _, _ in }
            )
        }
    }

    private struct PreviewFetchMovieListUseCase: FetchMovieListUseCase {
        func execute(list _: MovieList, page: Int) async throws -> MoviePage {
            MoviePage(
                page: page,
                movies: (1 ... 10).map {
                    Movie(id: $0, title: "Preview Movie \($0)", overview: "", voteAverage: 7.5, voteCount: 100)
                },
                totalPages: 1
            )
        }
    }
#endif
