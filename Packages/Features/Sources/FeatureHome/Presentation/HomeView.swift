//
//  HomeView.swift
//  TMDB
//
//  Created by Ahmed Raslan on 17/07/2026.
//

import CoreUI
import SwiftUI

/// Home tab placeholder. The real multi-section home lands in Sprint 3.
/// Navigation intent is reported through closures — the coordinator decides
/// what happens.
public struct HomeView: View {
    private let onSelectMovie: (Int) -> Void

    public init(onSelectMovie: @escaping (Int) -> Void) {
        self.onSelectMovie = onSelectMovie
    }

    public var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Text("Home lands in Sprint 3.", comment: "Home placeholder body")
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textSecondary)

            Button {
                onSelectMovie(550)
            } label: {
                Text("Open a movie (test push)", comment: "Home placeholder test-push button")
            }
        }
        .navigationTitle(Text("Home", comment: "Home tab title"))
    }
}

#Preview {
    NavigationStack {
        HomeView(onSelectMovie: { _ in })
    }
}
