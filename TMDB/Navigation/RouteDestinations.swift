//
//  RouteDestinations.swift
//  TMDB
//
//  Created by Ahmed Raslan on 17/07/2026.
//

import CoreModels
import FeatureFavorites
import FeatureHome
import FeatureMovieDetails
import FeatureProfile
import FeatureSearch
import SwiftUI

/// Route → view mapping for every feature. This is the only place feature
/// routes are resolved to concrete screens, which is what lets features stay
/// ignorant of each other (e.g. Home pushing MovieDetails).
enum RouteDestinations {
    /// Attaches every feature's `navigationDestination` mapping to a tab's
    /// `NavigationStack` content. Destinations that need dependencies get
    /// them from the coordinator (navigation) and the injected factories
    /// (view models) — never from a locator.
    @MainActor
    static func attach(
        to view: some View,
        coordinator: AppCoordinator,
        makeMovieListViewModel: @escaping @MainActor (HomeSection, TrendingWindow) -> MovieListViewModel
    ) -> some View {
        view
            .navigationDestination(for: HomeRoute.self) { route in
                switch route {
                case let .movieDetails(movieID):
                    MovieDetailsPlaceholderView(movieID: movieID)
                case let .seeAll(section, window):
                    // Assumes HomeRoute values are only ever pushed onto the
                    // Home tab's stack — true today because only Home's
                    // closures emit them. Revisit if another tab gains them.
                    MovieListView(
                        viewModel: makeMovieListViewModel(section, window),
                        onSelectMovie: { coordinator.home.push(.movieDetails(movieID: $0)) }
                    )
                }
            }
            .navigationDestination(for: SearchRoute.self) { route in
                switch route {
                case let .movieDetails(movieID):
                    MovieDetailsPlaceholderView(movieID: movieID)
                }
            }
            .navigationDestination(for: FavoritesRoute.self) { route in
                switch route {
                case let .movieDetails(movieID):
                    MovieDetailsPlaceholderView(movieID: movieID)
                }
            }
            .navigationDestination(for: ProfileRoute.self) { route in
                switch route {
                case .settings:
                    SettingsPlaceholderView()
                }
            }
    }
}
