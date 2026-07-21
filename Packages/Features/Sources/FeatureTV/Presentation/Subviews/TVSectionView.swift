//
//  TVSectionView.swift
//  TMDB
//
//  Created by Ahmed Raslan on 21/07/2026.
//

import CoreModels
import CoreUI
import SwiftUI

/// One TV list section: a title row and a state-driven horizontal carousel,
/// loading skeleton, or error-with-retry.
struct TVSectionView: View {
    let list: TVList
    let state: TVHomeViewModel.SectionState
    let posterURL: (MediaItem) -> URL?
    let onSelectShow: (Int) -> Void
    let onRetry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Self.title(for: list)
                .font(AppTypography.title)
                .padding(.horizontal, AppSpacing.lg)
            content
        }
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .idle, .loading:
            skeletonRow
        case let .error(message):
            errorRow(message)
        case .loaded([]):
            emptyRow
        case let .loaded(shows):
            carousel(shows)
        }
    }

    private func carousel(_ shows: [MediaItem]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(alignment: .top, spacing: AppSpacing.md) {
                ForEach(shows) { show in
                    PosterCard(
                        title: show.title,
                        posterURL: posterURL(show),
                        rating: show.voteCount > 0 ? show.voteAverage : nil,
                        accessibilityID: "tv.show.\(show.id)",
                        onSelect: { onSelectShow(show.id) }
                    )
                }
            }
            .padding(.horizontal, AppSpacing.lg)
        }
    }

    private var skeletonRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: AppSpacing.md) {
                ForEach(0 ..< 4) { _ in PosterCardSkeleton() }
            }
            .padding(.horizontal, AppSpacing.lg)
        }
        .scrollDisabled(true)
        .shimmering()
        .accessibilityElement()
        .accessibilityLabel(Text("Loading", comment: "VoiceOver label while a TV section loads"))
    }

    private var emptyRow: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "tv").accessibilityHidden(true)
            Text("Nothing here right now.", comment: "Empty TV section body")
                .font(AppTypography.body)
        }
        .foregroundStyle(AppColors.textSecondary)
        .frame(maxWidth: .infinity, minHeight: 100)
    }

    private func errorRow(_ message: LocalizedStringResource) -> some View {
        VStack(spacing: AppSpacing.md) {
            Text(message)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textSecondary)
            Button(action: onRetry) {
                Text("Retry", comment: "Retry a failed TV section")
                    .font(AppTypography.label)
            }
            .buttonStyle(.bordered)
            .tint(AppColors.brandSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 100)
    }

    private static func title(for list: TVList) -> Text {
        switch list {
        case .onTheAir: Text("On The Air", comment: "TV section: currently airing")
        case .popular: Text("Popular", comment: "TV section: popular shows")
        case .topRated: Text("Top Rated", comment: "TV section: highest rated shows")
        }
    }
}
