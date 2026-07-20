//
//  MovieDetailsView.swift
//  TMDB
//
//  Created by Ahmed Raslan on 19/07/2026.
//

import CoreModels
import CoreUI
import SwiftUI

/// The movie details screen: stretchy backdrop header, overview, cast,
/// trailers, and related carousels. Navigation intent is reported through
/// `onSelectMovie` — the coordinator decides what happens.
public struct MovieDetailsView: View {
    @State private var viewModel: MovieDetailsViewModel
    private let onSelectMovie: (Int) -> Void

    /// The view model moves into `@State` so repeated destination-builder
    /// evaluations for the same push reuse one instance.
    public init(viewModel: MovieDetailsViewModel, onSelectMovie: @escaping (Int) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onSelectMovie = onSelectMovie
    }

    public var body: some View {
        content
            .task { await viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            loadingSkeleton
        case let .error(message):
            errorView(message)
        case let .loaded(bundle):
            loadedView(bundle)
        }
    }

    private func loadedView(_ bundle: MovieDetailsBundle) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                DetailsHeaderView(
                    details: bundle.details,
                    backdropURL: viewModel.backdropURL(for: bundle.details)
                )
                overviewSection(bundle.details)
                CastSection(cast: bundle.cast, profileURL: viewModel.profileURL(for:))
                VideosSection(
                    videos: viewModel.featuredVideos(in: bundle),
                    watchURL: viewModel.watchURL(for:),
                    thumbnailURL: viewModel.thumbnailURL(for:)
                )
                RelatedSection(
                    title: Text("Similar", comment: "Similar movies section title"),
                    accessibilityPrefix: "details.similar",
                    movies: bundle.similar,
                    posterURL: viewModel.posterURL(for:),
                    onSelectMovie: onSelectMovie
                )
                RelatedSection(
                    title: Text("Recommended", comment: "Recommended movies section title"),
                    accessibilityPrefix: "details.recommended",
                    movies: bundle.recommendations,
                    posterURL: viewModel.posterURL(for:),
                    onSelectMovie: onSelectMovie
                )
            }
            .padding(.bottom, AppSpacing.xxl)
        }
        .coordinateSpace(name: DetailsHeaderView.scrollSpace)
        .navigationTitle(bundle.details.title)
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
            .ignoresSafeArea(edges: .top)
            .toolbar { savedButtons }
    }

    @ToolbarContentBuilder
    private var savedButtons: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                Task { await viewModel.toggleWatchlist() }
            } label: {
                Label {
                    Text("Watchlist", comment: "Watchlist toggle button")
                } icon: {
                    Image(systemName: viewModel.isOnWatchlist ? "bookmark.fill" : "bookmark")
                }
            }
            .tint(AppColors.brandSecondary)
            .accessibilityIdentifier("details.watchlist")
            .accessibilityValue(viewModel.isOnWatchlist
                ? Text("On watchlist", comment: "Watchlist button state: on")
                : Text("Not on watchlist", comment: "Watchlist button state: off"))
        }
        ToolbarItem(placement: .primaryAction) {
            Button {
                Task { await viewModel.toggleFavorite() }
            } label: {
                Label {
                    Text("Favorite", comment: "Favorite toggle button")
                } icon: {
                    Image(systemName: viewModel.isFavorite ? "heart.fill" : "heart")
                }
            }
            .tint(AppColors.error)
            .accessibilityIdentifier("details.favorite")
            .accessibilityValue(viewModel.isFavorite
                ? Text("Favorited", comment: "Favorite button state: on")
                : Text("Not favorited", comment: "Favorite button state: off"))
        }
    }

    @ViewBuilder
    private func overviewSection(_ details: MovieDetails) -> some View {
        if !details.overview.isEmpty {
            Text(details.overview)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textPrimary)
                .padding(.horizontal, AppSpacing.lg)
        }
    }

    private var loadingSkeleton: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            // Matches the loaded backdrop's under-status-bar placement so the
            // skeleton → content transition doesn't jump.
            SkeletonBox(cornerRadius: 0)
                .frame(height: 220)
            Group {
                SkeletonBox().frame(width: 220, height: 24)
                SkeletonBox().frame(width: 140, height: 14)
                SkeletonBox().frame(maxWidth: .infinity, minHeight: 80)
            }
            .padding(.horizontal, AppSpacing.lg)
            Spacer()
        }
        .shimmering()
        .ignoresSafeArea(edges: .top)
        .accessibilityElement()
        .accessibilityLabel(Text("Loading", comment: "VoiceOver label while movie details load"))
    }

    private func errorView(_ message: LocalizedStringResource) -> some View {
        VStack(spacing: AppSpacing.md) {
            Text(message)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textSecondary)
            Button {
                Task { await viewModel.load() }
            } label: {
                Text("Retry", comment: "Retry loading movie details")
                    .font(AppTypography.label)
            }
            .buttonStyle(.bordered)
            .tint(AppColors.brandSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
