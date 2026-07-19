//
//  PosterCard.swift
//  TMDB
//
//  Created by Ahmed Raslan on 19/07/2026.
//

import SwiftUI

/// Shared card metrics — the skeleton twin references the same values so its
/// footprint match stays mechanical, not manual.
private enum PosterCardLayout {
    static let posterWidth: CGFloat = 130
    static let posterHeight: CGFloat = 195
}

/// A tappable poster card: image, two-line title, optional rating. Shared by
/// every feature that renders movie/show carousels or grids. Takes plain
/// values (not domain entities) so CoreUI stays model-agnostic.
public struct PosterCard: View {
    private let title: String
    private let posterURL: URL?
    private let rating: Double?
    private let accessibilityID: String?
    private let onSelect: () -> Void

    /// - Parameters:
    ///   - rating: 0–10 score; pass `nil` to hide the rating row.
    ///   - accessibilityID: Stable identifier for UI tests.
    public init(
        title: String,
        posterURL: URL?,
        rating: Double? = nil,
        accessibilityID: String? = nil,
        onSelect: @escaping () -> Void
    ) {
        self.title = title
        self.posterURL = posterURL
        self.rating = rating
        self.accessibilityID = accessibilityID
        self.onSelect = onSelect
    }

    public var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                poster
                Text(title)
                    .font(AppTypography.label)
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(2, reservesSpace: true)
                ratingRow
            }
            .frame(width: PosterCardLayout.posterWidth)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(accessibilityID ?? "")
    }

    private var poster: some View {
        RemoteImage(url: posterURL) { image in
            image
                .resizable()
                .scaledToFill()
        } placeholder: {
            RoundedRectangle(cornerRadius: AppRadius.md)
                .fill(AppColors.brandPrimary.opacity(0.15))
                .overlay {
                    Image(systemName: "film")
                        .font(.title)
                        .foregroundStyle(AppColors.textSecondary)
                        .accessibilityHidden(true)
                }
        }
        .frame(width: PosterCardLayout.posterWidth, height: PosterCardLayout.posterHeight)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    }

    @ViewBuilder
    private var ratingRow: some View {
        if let rating {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "star.fill")
                    .foregroundStyle(AppColors.rating)
                    .accessibilityHidden(true)
                Text(rating, format: .number.precision(.fractionLength(1)))
                    .foregroundStyle(AppColors.textSecondary)
            }
            .font(AppTypography.caption)
            .accessibilityLabel(Text(
                "Rated \(rating, format: .number.precision(.fractionLength(1))) out of 10",
                comment: "VoiceOver label for a poster card's rating"
            ))
        }
    }
}

/// Skeleton twin of `PosterCard` — matches its footprint so content landing
/// doesn't shift surrounding layout.
public struct PosterCardSkeleton: View {
    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            SkeletonBox(cornerRadius: AppRadius.md)
                .frame(width: PosterCardLayout.posterWidth, height: PosterCardLayout.posterHeight)
            SkeletonBox()
                .frame(width: 110, height: 32)
            SkeletonBox()
                .frame(width: 70, height: 14)
        }
    }
}

#Preview {
    HStack(alignment: .top, spacing: AppSpacing.md) {
        PosterCard(title: "Fight Club", posterURL: nil, rating: 8.4, onSelect: {})
        PosterCardSkeleton()
    }
    .padding(AppSpacing.lg)
}
