//
//  MovieDetailsPlaceholderView.swift
//  TMDB
//
//  Created by Ahmed Raslan on 17/07/2026.
//

import CoreUI
import SwiftUI

/// Destination placeholder proving push navigation works. Replaced by the
/// real details screen in Sprint 3.
public struct MovieDetailsPlaceholderView: View {
    private let movieID: Int

    public init(movieID: Int) {
        self.movieID = movieID
    }

    public var body: some View {
        VStack(spacing: AppSpacing.md) {
            Text("Movie Details", comment: "Placeholder details title")
                .font(AppTypography.screenTitle)
            Text(verbatim: "movieID: \(movieID)")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
        }
        .navigationTitle(Text("Details", comment: "Details nav title"))
    }
}

#Preview {
    NavigationStack {
        MovieDetailsPlaceholderView(movieID: 550)
    }
}
