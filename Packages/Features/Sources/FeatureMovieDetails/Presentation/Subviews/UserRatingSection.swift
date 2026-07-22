//
//  UserRatingSection.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

import CoreUI
import SwiftUI

/// The signed-in user's own rating — five tappable stars mapping to TMDB's
/// 0.5–10 scale (star _n_ ⇒ value _2n_). Tapping a filled star's own value
/// clears the rating. Writes are optimistic; the view model rolls back on
/// failure.
struct UserRatingSection: View {
    /// Current rating (0.5–10), or `nil` when unrated.
    let rating: Double?
    /// Sets the rating to `value` (0.5–10).
    let onRate: (Double) -> Void
    /// Clears the rating.
    let onClear: () -> Void

    private static let starCount = 5

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Your rating", bundle: .module, comment: "Section title for the user's own movie rating")
                .font(AppTypography.label)
                .foregroundStyle(AppColors.textSecondary)

            HStack(spacing: AppSpacing.sm) {
                ForEach(1 ... Self.starCount, id: \.self) { star in
                    starButton(star)
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("details.rating")
            .accessibilityValue(ratingDescription)
        }
        .padding(.horizontal, AppSpacing.lg)
    }

    private func starButton(_ star: Int) -> some View {
        let value = Double(star * 2)
        let isFilled = (rating ?? 0) >= value
        return Button {
            if rating == value {
                onClear()
            } else {
                onRate(value)
            }
        } label: {
            Image(systemName: isFilled ? "star.fill" : "star")
                .foregroundStyle(isFilled ? AppColors.rating : AppColors.textSecondary)
                .font(.title3)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("details.rating.star.\(star)")
        .accessibilityLabel(Text("\(star) star", bundle: .module, comment: "VoiceOver label for a rating star"))
    }

    private var ratingDescription: Text {
        if let rating {
            Text("\(Int(rating.rounded())) out of 10", bundle: .module, comment: "VoiceOver value for the current rating")
        } else {
            Text("Not rated", bundle: .module, comment: "VoiceOver value when the user hasn't rated the movie")
        }
    }
}
