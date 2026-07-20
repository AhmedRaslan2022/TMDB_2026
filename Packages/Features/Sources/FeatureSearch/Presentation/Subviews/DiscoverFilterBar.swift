//
//  DiscoverFilterBar.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

import CoreUI
import SwiftUI

/// The Discover screen's filter controls: sort/year/rating menus and a
/// horizontally scrolling genre chip row. Emits intent through closures — it
/// holds no state of its own.
struct DiscoverFilterBar: View {
    let genres: [MovieGenre]
    let filters: DiscoverFilters
    let availableYears: [Int]
    let availableRatings: [Double]
    let onToggleGenre: (Int) -> Void
    let onSetSort: (MovieSortOption) -> Void
    let onSetYear: (Int?) -> Void
    let onSetRating: (Double?) -> Void
    let onClear: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            menus
            if !genres.isEmpty {
                genreChips
            }
        }
        .padding(.vertical, AppSpacing.sm)
    }

    private var menus: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                sortMenu
                yearMenu
                ratingMenu
                if filters.isActive {
                    Button(role: .destructive, action: onClear) {
                        Text("Clear", comment: "Clears all Discover filters")
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("discover.clear")
                }
            }
            .padding(.horizontal, AppSpacing.lg)
        }
    }

    private var sortMenu: some View {
        Menu {
            ForEach(MovieSortOption.allCases) { option in
                menuButton(Self.sortLabel(option), isSelected: option == filters.sort) {
                    onSetSort(option)
                }
            }
        } label: {
            menuLabel(Text("Sort", comment: "Discover sort menu label"))
        }
        .accessibilityIdentifier("discover.sort")
    }

    private var yearMenu: some View {
        Menu {
            menuButton(
                Text("Any Year", comment: "Discover year filter: no year selected"),
                isSelected: filters.year == nil
            ) { onSetYear(nil) }
            ForEach(availableYears, id: \.self) { year in
                menuButton(Text(verbatim: String(year)), isSelected: filters.year == year) {
                    onSetYear(year)
                }
            }
        } label: {
            menuLabel(Text("Year", comment: "Discover year menu label"))
        }
        .accessibilityIdentifier("discover.year")
    }

    private var ratingMenu: some View {
        Menu {
            menuButton(
                Text("Any Rating", comment: "Discover rating filter: no minimum"),
                isSelected: filters.minimumRating == nil
            ) { onSetRating(nil) }
            ForEach(availableRatings, id: \.self) { rating in
                menuButton(
                    Text("\(Int(rating))+", comment: "Discover minimum-rating option"),
                    isSelected: filters.minimumRating == rating
                ) { onSetRating(rating) }
            }
        } label: {
            menuLabel(Text("Rating", comment: "Discover rating menu label"))
        }
        .accessibilityIdentifier("discover.rating")
    }

    /// A menu row that shows a leading checkmark when it's the active choice.
    private func menuButton(_ title: Text, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            if isSelected {
                Label { title } icon: { Image(systemName: "checkmark") }
            } else {
                title
            }
        }
    }

    /// The tappable menu trigger — a bordered pill.
    private func menuLabel(_ title: Text) -> some View {
        HStack(spacing: AppSpacing.xs) {
            title
            Image(systemName: "chevron.down")
                .font(.caption2)
        }
        .font(AppTypography.label)
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.xs)
        .background(AppColors.textSecondary.opacity(0.12), in: Capsule())
    }

    private var genreChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                ForEach(genres) { genre in
                    let isSelected = filters.genreIDs.contains(genre.id)
                    Button {
                        onToggleGenre(genre.id)
                    } label: {
                        Text(verbatim: genre.name)
                            .font(AppTypography.label)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(isSelected ? AppColors.brandSecondary : AppColors.textSecondary.opacity(0.3))
                    .accessibilityIdentifier("discover.genre.\(genre.id)")
                    .accessibilityAddTraits(isSelected ? [.isSelected] : [])
                }
            }
            .padding(.horizontal, AppSpacing.lg)
        }
    }

    private static func sortLabel(_ option: MovieSortOption) -> Text {
        switch option {
        case .popularity: Text("Popularity", comment: "Sort option: most popular")
        case .rating: Text("Top Rated", comment: "Sort option: highest rated")
        case .newest: Text("Newest", comment: "Sort option: most recent release")
        case .title: Text("A–Z", comment: "Sort option: alphabetical by title")
        }
    }
}
