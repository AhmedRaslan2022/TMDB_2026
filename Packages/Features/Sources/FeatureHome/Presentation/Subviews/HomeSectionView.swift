//
//  HomeSectionView.swift
//  TMDB
//
//  Created by Ahmed Raslan on 18/07/2026.
//

import CoreModels
import CoreUI
import SwiftUI

/// One Home section: title row (plus the day/week toggle on trending) and a
/// state-driven body — carousel, loading row, error with retry, or empty.
struct HomeSectionView: View {
    let section: HomeSection
    let state: HomeViewModel.SectionState
    let trendingWindow: TrendingWindow
    let posterURL: (Movie) -> URL?
    let onSelectMovie: (Int) -> Void
    let onSelectWindow: (TrendingWindow) -> Void
    let onSeeAll: () -> Void
    let onRetry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            header
            content
        }
    }

    private var header: some View {
        HStack(spacing: AppSpacing.md) {
            Text(section.title)
                .font(AppTypography.title)
            Spacer()
            if section == .trending {
                windowPicker
            }
            if hasContent {
                seeAllButton
            }
        }
        .padding(.horizontal, AppSpacing.lg)
    }

    private var hasContent: Bool {
        if case let .loaded(movies) = state, !movies.isEmpty {
            true
        } else {
            false
        }
    }

    private var seeAllButton: some View {
        Button(action: onSeeAll) {
            Text("See All", comment: "Opens the full paginated list for a home section")
                .font(AppTypography.label)
                .foregroundStyle(AppColors.brandSecondary)
        }
        .accessibilityIdentifier("home.seeAll.\(String(describing: section))")
    }

    private var windowPicker: some View {
        Picker(
            selection: Binding(get: { trendingWindow }, set: onSelectWindow)
        ) {
            Text("Today", comment: "Trending window: today").tag(TrendingWindow.day)
            Text("This Week", comment: "Trending window: this week").tag(TrendingWindow.week)
        } label: {
            Text("Trending window", comment: "Accessibility label for the trending window picker")
        }
        .pickerStyle(.segmented)
        .fixedSize()
        .accessibilityIdentifier("home.trendingWindow")
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .idle, .loading:
            MoviePosterSkeletonRow()
        case let .error(message):
            errorRow(message)
        case .loaded([]):
            emptyRow
        case let .loaded(movies):
            carousel(movies)
        }
    }

    private var emptyRow: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "film.stack")
                .accessibilityHidden(true)
            Text("Nothing here right now.", comment: "Empty home section body")
                .font(AppTypography.body)
        }
        .foregroundStyle(AppColors.textSecondary)
        .frame(maxWidth: .infinity, minHeight: 100)
    }

    private func carousel(_ movies: [Movie]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(alignment: .top, spacing: AppSpacing.md) {
                ForEach(movies) { movie in
                    PosterCard(
                        title: movie.title,
                        posterURL: posterURL(movie),
                        rating: movie.voteCount > 0 ? movie.voteAverage : nil,
                        accessibilityID: "home.movie.\(movie.id)",
                        onSelect: { onSelectMovie(movie.id) }
                    )
                }
            }
            .padding(.horizontal, AppSpacing.lg)
        }
    }

    private func errorRow(_ message: LocalizedStringResource) -> some View {
        VStack(spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "exclamationmark.triangle")
                    .accessibilityHidden(true)
                Text(message)
                    .font(AppTypography.body)
            }
            .foregroundStyle(AppColors.textSecondary)
            Button(action: onRetry) {
                Text("Retry", comment: "Retry a failed home section")
                    .font(AppTypography.label)
            }
            .buttonStyle(.bordered)
            .tint(AppColors.brandSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 100)
    }
}
