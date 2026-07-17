import CoreUI
import SwiftUI

/// Favorites tab placeholder. Offline-first favorites land in Sprint 4.
public struct FavoritesView: View {
    private let onSelectMovie: (Int) -> Void

    public init(onSelectMovie: @escaping (Int) -> Void) {
        self.onSelectMovie = onSelectMovie
    }

    public var body: some View {
        Text("Favorites land in Sprint 4.", comment: "Favorites placeholder body")
            .font(AppTypography.body)
            .foregroundStyle(AppColors.textSecondary)
            .navigationTitle(Text("Favorites", comment: "Favorites tab title"))
    }
}

#Preview {
    NavigationStack {
        FavoritesView(onSelectMovie: { _ in })
    }
}
