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
import FeaturePerson
import FeatureProfile
import FeatureSearch
import FeatureTV
import SwiftUI

/// The screen-scoped view-model factories the route table needs, bundled so the
/// wiring stays under the parameter-count budget as features are added.
@MainActor
struct RouteViewModelFactories {
    let movieList: @MainActor (HomeSection, TrendingWindow) -> MovieListViewModel
    let movieDetails: @MainActor (Int) -> MovieDetailsViewModel
    let discover: @MainActor () -> DiscoverViewModel
    let settings: @MainActor () -> SettingsViewModel
    let tvDetails: @MainActor (Int) -> TVDetailsViewModel
    let person: @MainActor (Int) -> PersonViewModel
}

/// Route → view mapping for every feature. This is the only place feature
/// routes are resolved to concrete screens, which is what lets features stay
/// ignorant of each other (e.g. Home pushing MovieDetails, or a person's TV
/// credit pushing TV details within the same tab — the 6.5 deep graph).
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
                favoritesDestination(route, coordinator, factories)
            }
            .navigationDestination(for: TVRoute.self) { route in
                switch route {
                case let .showDetails(showID):
                    TVDetailsView(
                        viewModel: factories.tvDetails(showID),
                        onSelectShow: { coordinator.tv.push(.showDetails(showID: $0)) }
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
        let home = coordinator.home
        switch route {
        case let .movieDetails(movieID):
            MovieDetailsView(
                viewModel: factories.movieDetails(movieID),
                onSelectMovie: { home.push(.movieDetails(movieID: $0)) },
                onSelectPerson: { home.push(.person(personID: $0)) }
            )
        case let .seeAll(section, window):
            MovieListView(
                viewModel: factories.movieList(section, window),
                onSelectMovie: { home.push(.movieDetails(movieID: $0)) }
            )
        case let .tvDetails(showID):
            TVDetailsView(
                viewModel: factories.tvDetails(showID),
                onSelectShow: { home.push(.tvDetails(showID: $0)) }
            )
        case let .person(personID):
            PersonView(
                viewModel: factories.person(personID),
                onSelectTitle: { media in
                    switch media.mediaType {
                    case .movie: home.push(.movieDetails(movieID: media.id))
                    case .tv: home.push(.tvDetails(showID: media.id))
                    }
                }
            )
        }
    }

    @MainActor @ViewBuilder
    private static func searchDestination(
        _ route: SearchRoute,
        _ coordinator: AppCoordinator,
        _ factories: RouteViewModelFactories
    ) -> some View {
        let search = coordinator.search
        switch route {
        case let .movieDetails(movieID):
            MovieDetailsView(
                viewModel: factories.movieDetails(movieID),
                onSelectMovie: { search.push(.movieDetails(movieID: $0)) },
                onSelectPerson: { search.push(.person(personID: $0)) }
            )
        case .discover:
            DiscoverView(
                viewModel: factories.discover(),
                onSelectMovie: { search.push(.movieDetails(movieID: $0)) }
            )
        case let .tvDetails(showID):
            TVDetailsView(
                viewModel: factories.tvDetails(showID),
                onSelectShow: { search.push(.tvDetails(showID: $0)) }
            )
        case let .person(personID):
            PersonView(
                viewModel: factories.person(personID),
                onSelectTitle: { media in
                    switch media.mediaType {
                    case .movie: search.push(.movieDetails(movieID: media.id))
                    case .tv: search.push(.tvDetails(showID: media.id))
                    }
                }
            )
        }
    }

    @MainActor @ViewBuilder
    private static func favoritesDestination(
        _ route: FavoritesRoute,
        _ coordinator: AppCoordinator,
        _ factories: RouteViewModelFactories
    ) -> some View {
        let favorites = coordinator.favorites
        switch route {
        case let .movieDetails(movieID):
            MovieDetailsView(
                viewModel: factories.movieDetails(movieID),
                onSelectMovie: { favorites.push(.movieDetails(movieID: $0)) },
                onSelectPerson: { favorites.push(.person(personID: $0)) }
            )
        case let .tvDetails(showID):
            TVDetailsView(
                viewModel: factories.tvDetails(showID),
                onSelectShow: { favorites.push(.tvDetails(showID: $0)) }
            )
        case let .person(personID):
            PersonView(
                viewModel: factories.person(personID),
                onSelectTitle: { media in
                    switch media.mediaType {
                    case .movie: favorites.push(.movieDetails(movieID: media.id))
                    case .tv: favorites.push(.tvDetails(showID: media.id))
                    }
                }
            )
        }
    }
}
