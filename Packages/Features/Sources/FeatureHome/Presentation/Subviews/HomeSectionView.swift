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
        }
        .padding(.horizontal, AppSpacing.lg)
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
            // Plain spinner row for now — task 3.5 replaces this with
            // skeleton shimmer placeholders.
            ProgressView()
                .frame(maxWidth: .infinity, minHeight: 195)
        case let .error(message):
            errorRow(message)
        case .loaded([]):
            Text("Nothing here right now.", comment: "Empty home section body")
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textSecondary)
                .frame(maxWidth: .infinity, minHeight: 100)
        case let .loaded(movies):
            carousel(movies)
        }
    }

    private func carousel(_ movies: [Movie]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(alignment: .top, spacing: AppSpacing.md) {
                ForEach(movies) { movie in
                    MoviePosterCard(
                        movie: movie,
                        posterURL: posterURL(movie),
                        onSelect: { onSelectMovie(movie.id) }
                    )
                }
            }
            .padding(.horizontal, AppSpacing.lg)
        }
    }

    private func errorRow(_ message: LocalizedStringResource) -> some View {
        VStack(spacing: AppSpacing.md) {
            Text(message)
                .font(AppTypography.body)
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
