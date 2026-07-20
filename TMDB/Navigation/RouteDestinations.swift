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

/// The screen-scoped view-model factories the route table needs, bundled so the
/// wiring stays under the parameter-count budget as features are added.
@MainActor
struct RouteViewModelFactories {
    let movieList: @MainActor (HomeSection, TrendingWindow) -> MovieListViewModel
    let movieDetails: @MainActor (Int) -> MovieDetailsViewModel
    let discover: @MainActor () -> DiscoverViewModel
    let settings: @MainActor () -> SettingsViewModel
}

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
        factories: RouteViewModelFactories
    ) -> some View {
        // Route values are assumed to be pushed only onto their own tab's
        // stack (HomeRoute → home, SearchRoute → search, …) — true today
        // because only that tab's closures emit them.
        view
            .navigationDestination(for: HomeRoute.self) { route in
                homeDestination(route, coordinator, factories)
            }
            .navigationDestination(for: SearchRoute.self) { route in
                searchDestination(route, coordinator, factories)
            }
            .navigationDestination(for: FavoritesRoute.self) { route in
                switch route {
                case let .movieDetails(movieID):
                    MovieDetailsView(
                        viewModel: factories.movieDetails(movieID),
                        onSelectMovie: { coordinator.favorites.push(.movieDetails(movieID: $0)) }
                    )
                }
            }
            .navigationDestination(for: ProfileRoute.self) { route in
                switch route {
                case .settings:
                    SettingsView(viewModel: factories.settings())
                }
            }
    }

    @MainActor @ViewBuilder
    private static func homeDestination(
        _ route: HomeRoute,
        _ coordinator: AppCoordinator,
        _ factories: RouteViewModelFactories
    ) -> some View {
        switch route {
        case let .movieDetails(movieID):
            MovieDetailsView(
                viewModel: factories.movieDetails(movieID),
                onSelectMovie: { coordinator.home.push(.movieDetails(movieID: $0)) }
            )
        case let .seeAll(section, window):
            MovieListView(
                viewModel: factories.movieList(section, window),
                onSelectMovie: { coordinator.home.push(.movieDetails(movieID: $0)) }
            )
        }
    }

    @MainActor @ViewBuilder
    private static func searchDestination(
        _ route: SearchRoute,
        _ coordinator: AppCoordinator,
        _ factories: RouteViewModelFactories
    ) -> some View {
        switch route {
        case let .movieDetails(movieID):
            MovieDetailsView(
                viewModel: factories.movieDetails(movieID),
                onSelectMovie: { coordinator.search.push(.movieDetails(movieID: $0)) }
            )
        case .discover:
            DiscoverView(
                viewModel: factories.discover(),
                onSelectMovie: { coordinator.search.push(.movieDetails(movieID: $0)) }
            )
        }
    }
}
