//
//  MoviePosterCard.swift
//  TMDB
//
//  Created by Ahmed Raslan on 18/07/2026.
//

import CoreModels
import CoreUI
import SwiftUI

/// One poster in a horizontal carousel: image, title, rating.
struct MoviePosterCard: View {
    let movie: Movie
    let posterURL: URL?
    let onSelect: () -> Void

    private enum Layout {
        static let posterWidth: CGFloat = 130
        static let posterHeight: CGFloat = 195
    }

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                poster
                Text(movie.title)
                    .font(AppTypography.label)
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(2, reservesSpace: true)
                rating
            }
            .frame(width: Layout.posterWidth)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("home.movie.\(movie.id)")
    }

    private var poster: some View {
        // AsyncImage is an interim: task 3.6 swaps in the actor-cached
        // loader without touching this card's layout.
        AsyncImage(url: posterURL) { phase in
            if case let .success(image) = phase {
                image
                    .resizable()
                    .scaledToFill()
            } else {
                placeholder
            }
        }
        .frame(width: Layout.posterWidth, height: Layout.posterHeight)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: AppRadius.md)
            .fill(AppColors.brandPrimary.opacity(0.15))
            .overlay {
                Image(systemName: "film")
                    .font(.title)
                    .foregroundStyle(AppColors.textSecondary)
                    .accessibilityHidden(true)
            }
    }

    @ViewBuilder
    private var rating: some View {
        if movie.voteCount > 0 {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "star.fill")
                    .foregroundStyle(AppColors.rating)
                    .accessibilityHidden(true)
                Text(movie.voteAverage, format: .number.precision(.fractionLength(1)))
                    .foregroundStyle(AppColors.textSecondary)
            }
            .font(AppTypography.caption)
            .accessibilityLabel(Text(
                "Rated \(movie.voteAverage, format: .number.precision(.fractionLength(1))) out of 10",
                comment: "VoiceOver label for a movie's rating"
            ))
        }
    }
}

#Preview {
    MoviePosterCard(
        movie: Movie(id: 550, title: "Fight Club", overview: "", voteAverage: 8.4, voteCount: 30000),
        posterURL: nil,
        onSelect: {}
    )
    .padding(AppSpacing.lg)
}
