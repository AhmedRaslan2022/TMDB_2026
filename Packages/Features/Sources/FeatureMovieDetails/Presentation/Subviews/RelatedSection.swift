//
//  RelatedSection.swift
//  TMDB
//
//  Created by Ahmed Raslan on 19/07/2026.
//

import CoreModels
import CoreUI
import SwiftUI

/// A titled carousel of related movies (similar / recommendations), built on
/// the shared `PosterCard`. Hidden entirely when empty.
struct RelatedSection: View {
    let title: Text
    /// Per-section identifier prefix — Similar and Recommended often contain
    /// the same movie, so IDs must not collide across sections.
    let accessibilityPrefix: String
    let movies: [Movie]
    let posterURL: (Movie) -> URL?
    let onSelectMovie: (Int) -> Void

    var body: some View {
        if !movies.isEmpty {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                title
                    .font(AppTypography.title)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.horizontal, AppSpacing.lg)
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(alignment: .top, spacing: AppSpacing.md) {
                        ForEach(movies) { movie in
                            PosterCard(
                                title: movie.title,
                                posterURL: posterURL(movie),
                                rating: movie.voteCount > 0 ? movie.voteAverage : nil,
                                accessibilityID: "\(accessibilityPrefix).\(movie.id)",
                                onSelect: { onSelectMovie(movie.id) }
                            )
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                }
            }
        }
    }
}
