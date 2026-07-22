//
//  MoviePosterSkeletonRow.swift
//  TMDB
//
//  Created by Ahmed Raslan on 18/07/2026.
//

import CoreUI
import SwiftUI

/// A carousel-shaped loading row of shimmering poster skeletons. Hidden from
/// accessibility — VoiceOver users hear the section title, not placeholder
/// noise.
struct MoviePosterSkeletonRow: View {
    var body: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: AppSpacing.md) {
                ForEach(0 ..< 4) { _ in
                    PosterCardSkeleton()
                }
            }
            .padding(.horizontal, AppSpacing.lg)
        }
        .scrollDisabled(true)
        .shimmering()
        .accessibilityHidden(true)
    }
}

#Preview {
    MoviePosterSkeletonRow()
}
