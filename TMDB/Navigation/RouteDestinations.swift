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
        makeMovieListViewModel: @escaping @MainActor (HomeSection, TrendingWindow) -> MovieListViewModel,
        makeMovieDetailsViewModel: @escaping @MainActor (Int) -> MovieDetailsViewModel
    ) -> some View {
        // Route values are assumed to be pushed only onto their own tab's
        // stack (HomeRoute → home, SearchRoute → search, …) — true today
        // because only that tab's closures emit them.
        view
            .navigationDestination(for: HomeRoute.self) { route in
                switch route {
                case let .movieDetails(movieID):
                    MovieDetailsView(
                        viewModel: makeMovieDetailsViewModel(movieID),
                        onSelectMovie: { coordinator.home.push(.movieDetails(movieID: $0)) }
                    )
                case let .seeAll(section, window):
                    MovieListView(
                        viewModel: makeMovieListViewModel(section, window),
                        onSelectMovie: { coordinator.home.push(.movieDetails(movieID: $0)) }
                    )
                }
            }
            .navigationDestination(for: SearchRoute.self) { route in
                switch route {
                case let .movieDetails(movieID):
                    MovieDetailsView(
                        viewModel: makeMovieDetailsViewModel(movieID),
                        onSelectMovie: { coordinator.search.push(.movieDetails(movieID: $0)) }
                    )
                }
            }
            .navigationDestination(for: FavoritesRoute.self) { route in
                switch route {
                case let .movieDetails(movieID):
                    MovieDetailsView(
                        viewModel: makeMovieDetailsViewModel(movieID),
                        onSelectMovie: { coordinator.favorites.push(.movieDetails(movieID: $0)) }
                    )
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
