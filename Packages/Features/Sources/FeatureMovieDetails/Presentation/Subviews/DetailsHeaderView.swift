//
//  DetailsHeaderView.swift
//  TMDB
//
//  Created by Ahmed Raslan on 19/07/2026.
//

import CoreUI
import SwiftUI

/// Backdrop that stretches on pull-down, then the title block: title,
/// tagline, year · runtime · genres, and the rating ring.
struct DetailsHeaderView: View {
    /// Coordinate space the parent `ScrollView` must declare for the
    /// stretch effect to measure against.
    static let scrollSpace = "details.scroll"

    let details: MovieDetails
    let backdropURL: URL?

    private enum Layout {
        static let backdropHeight: CGFloat = 220
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            stretchyBackdrop
            titleBlock
        }
    }

    private var stretchyBackdrop: some View {
        GeometryReader { proxy in
            let stretch = max(0, proxy.frame(in: .named(Self.scrollSpace)).minY)
            RemoteImage(url: backdropURL) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Rectangle()
                    .fill(AppColors.brandPrimary.opacity(0.2))
            }
            .frame(width: proxy.size.width, height: Layout.backdropHeight + stretch)
            .clipped()
            .offset(y: -stretch)
        }
        .frame(height: Layout.backdropHeight)
        .accessibilityHidden(true)
    }

    private var titleBlock: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(details.title)
                    .font(AppTypography.screenTitle)
                    .accessibilityIdentifier("details.title")
                if let tagline = details.tagline {
                    Text(tagline)
                        .font(AppTypography.body.italic())
                        .foregroundStyle(AppColors.textSecondary)
                }
                metaRow
            }
            Spacer()
            if details.voteCount > 0 {
                RatingRing(score: details.voteAverage)
            }
        }
        .padding(.horizontal, AppSpacing.lg)
    }

    private var metaRow: some View {
        Text(metaComponents.joined(separator: " · "))
            .font(AppTypography.caption)
            .foregroundStyle(AppColors.textSecondary)
    }

    private var metaComponents: [String] {
        var components: [String] = []
        if let releaseDate = details.releaseDate {
            components.append(releaseDate.formatted(.dateTime.year()))
        }
        if let minutes = details.runtimeMinutes {
            components.append(Duration.seconds(minutes * 60)
                .formatted(.units(allowed: [.hours, .minutes], width: .narrow)))
        }
        if !details.genres.isEmpty {
            components.append(details.genres.map(\.name).joined(separator: ", "))
        }
        return components
    }
}
