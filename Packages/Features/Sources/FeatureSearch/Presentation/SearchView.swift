//
//  SearchView.swift
//  TMDB
//
//  Created by Ahmed Raslan on 17/07/2026.
//

import CoreUI
import SwiftUI

/// Search tab placeholder. Debounced search lands in Sprint 4.
public struct SearchView: View {
    private let onSelectMovie: (Int) -> Void

    public init(onSelectMovie: @escaping (Int) -> Void) {
        self.onSelectMovie = onSelectMovie
    }

    public var body: some View {
        Text("Search lands in Sprint 4.", comment: "Search placeholder body")
            .font(AppTypography.body)
            .foregroundStyle(AppColors.textSecondary)
            .navigationTitle(Text("Search", comment: "Search tab title"))
    }
}

#Preview {
    NavigationStack {
        SearchView(onSelectMovie: { _ in })
    }
}
