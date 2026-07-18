//
//  MoviePosterSkeletonRow.swift
//  TMDB
//
//  Created by Ahmed Raslan on 18/07/2026.
//

import CoreUI
import SwiftUI

/// Skeleton twin of `MoviePosterCard` — matches its footprint (poster,
/// reserved two-line title, rating row) so content landing doesn't shift the
/// layout below.
struct MoviePosterCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            SkeletonBox(cornerRadius: AppRadius.md)
                .frame(width: 130, height: 195)
            SkeletonBox()
                .frame(width: 110, height: 32)
            SkeletonBox()
                .frame(width: 70, height: 14)
        }
    }
}

/// A carousel-shaped loading row of shimmering poster skeletons. Hidden from
/// accessibility — VoiceOver users hear the section title, not placeholder
/// noise.
struct MoviePosterSkeletonRow: View {
    var body: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: AppSpacing.md) {
                ForEach(0 ..< 4) { _ in
                    MoviePosterCardSkeleton()
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
