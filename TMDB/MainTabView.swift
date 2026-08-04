//
//  MainTabView.swift
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

/// The main shell: five tabs (Home · TV · Search · Favorites · Profile), each
/// owning a `NavigationStack` bound to its child coordinator's path. All pushes
/// go through the coordinators.
struct MainTabView: View {
    @Bindable var coordinator: AppCoordinator
    let homeViewModel: HomeViewModel
    let tvHomeViewModel: TVHomeViewModel
    let searchViewModel: SearchViewModel
    let favoritesViewModel: FavoritesViewModel
    let profileViewModel: ProfileViewModel
    let debugEnvironmentName: String?
    let makeMovieListViewModel: @MainActor @Sendable (HomeSection, TrendingWindow) -> MovieListViewModel
    let makeMovieDetailsViewModel: @MainActor @Sendable (Int) -> MovieDetailsViewModel
    let makeDiscoverViewModel: @MainActor @Sendable () -> DiscoverViewModel
    let makeSettingsViewModel: @MainActor @Sendable () -> SettingsViewModel
    let makeTVDetailsViewModel: @MainActor @Sendable (Int) -> TVDetailsViewModel
    let makePersonViewModel: @MainActor @Sendable (Int) -> PersonViewModel

    /// One place to wire the route table's dependencies for every tab.
    private func attached(_ view: some View) -> some View {
        RouteDestinations.attach(
            to: view,
            coordinator: coordinator,
            factories: RouteViewModelFactories(
                movieList: makeMovieListViewModel,
                movieDetails: makeMovieDetailsViewModel,
                discover: makeDiscoverViewModel,
                settings: makeSettingsViewModel,
                tvDetails: makeTVDetailsViewModel,
                person: makePersonViewModel
            )
        )
    }

    var body: some View {
        TabView(selection: $coordinator.selectedTab) {
            homeTab
                .tabItem {
                    Label {
                        Text("Home", comment: "Home tab label")
                    } icon: {
                        Image(systemName: "house")
                    }
                }
                .tag(AppTab.home)

            tvTab
                .tabItem {
                    Label {
                        Text("TV", comment: "TV tab label")
                    } icon: {
                        Image(systemName: "tv")
                    }
                }
                .tag(AppTab.tv)

            searchTab
                .tabItem {
                    Label {
                        Text("Search", comment: "Search tab label")
                    } icon: {
                        Image(systemName: "magnifyingglass")
                    }
                }
                .tag(AppTab.search)

            favoritesTab
                .tabItem {
                    Label {
                        Text("Favorites", comment: "Favorites tab label")
                    } icon: {
                        Image(systemName: "heart")
                    }
                }
                .tag(AppTab.favorites)

            profileTab
                .tabItem {
                    Label {
                        Text("Profile", comment: "Profile tab label")
                    } icon: {
                        Image(systemName: "person")
                    }
                }
                .tag(AppTab.profile)
        }
    }

    private var homeTab: some View {
        @Bindable var home = coordinator.home
        return NavigationStack(path: $home.path) {
            attached(HomeView(
                viewModel: homeViewModel,
                onSelectMovie: { coordinator.home.push(.movieDetails(movieID: $0)) },
                onSeeAll: { coordinator.home.push(.seeAll(section: $0, window: $1)) }
            ))
        }
    }

    private var tvTab: some View {
        @Bindable var tv = coordinator.tv
        return NavigationStack(path: $tv.path) {
            attached(TVHomeView(
                viewModel: tvHomeViewModel,
                onSelectShow: { coordinator.tv.push(.showDetails(showID: $0)) }
            ))
        }
    }

    private var searchTab: some View {
        @Bindable var search = coordinator.search
        return NavigationStack(path: $search.path) {
            attached(SearchView(
                viewModel: searchViewModel,
                onSelectMovie: { coordinator.search.push(.movieDetails(movieID: $0)) },
                onOpenDiscover: { coordinator.search.push(.discover) }
            ))
        }
    }

    private var favoritesTab: some View {
        @Bindable var favorites = coordinator.favorites
        return NavigationStack(path: $favorites.path) {
            attached(FavoritesView(
                viewModel: favoritesViewModel,
                onSelectMovie: { coordinator.favorites.push(.movieDetails(movieID: $0)) }
            ))
        }
    }

    private var profileTab: some View {
        @Bindable var profile = coordinator.profile
        return NavigationStack(path: $profile.path) {
            attached(ProfileView(
                viewModel: profileViewModel,
                debugEnvironmentName: debugEnvironmentName,
                onOpenSettings: { coordinator.profile.push(.settings) },
                onShowAbout: { coordinator.presentSheet(.about) },
                onShowWhatsNew: { coordinator.presentFullScreenCover(.whatsNew) },
                onSignOut: { coordinator.signOut() }
            ))
        }
    }
}

#if DEBUG
    #Preview {
        MainTabView(
            coordinator: AppCoordinator(auth: .stub),
            homeViewModel: HomeViewModel(
                fetchMovieList: StubFetchMovieListUseCase(),
                imageBaseURL: URL(fileURLWithPath: "/")
            ),
            tvHomeViewModel: TVHomeViewModel(
                fetchTVList: StubFetchTVListUseCase(),
                imageBaseURL: URL(fileURLWithPath: "/")
            ),
            searchViewModel: SearchViewModel(
                searchMovies: StubSearchMoviesUseCase(),
                recentSearches: StubRecentSearchesRepository(),
                imageBaseURL: URL(fileURLWithPath: "/")
            ),
            favoritesViewModel: FavoritesViewModel(
                repository: StubFavoritesRepository.shared,
                imageBaseURL: URL(fileURLWithPath: "/")
            ),
            profileViewModel: ProfileViewModel(
                repository: StubProfileRepository(),
                imageBaseURL: URL(fileURLWithPath: "/")
            ),
            debugEnvironmentName: "Dev",
            makeMovieListViewModel: { section, window in
                MovieListViewModel(
                    section: section,
                    window: window,
                    fetchMovieList: StubFetchMovieListUseCase(),
                    imageBaseURL: URL(fileURLWithPath: "/")
                )
            },
            makeMovieDetailsViewModel: { movieID in
                MovieDetailsViewModel(
                    movieID: movieID,
                    fetchDetails: StubFetchMovieDetailsUseCase(),
                    favorites: StubFavoriteToggling(),
                    watchlist: StubWatchlistToggling(),
                    rating: StubMovieRatingRepository(),
                    imageBaseURL: URL(fileURLWithPath: "/")
                )
            },
            makeDiscoverViewModel: {
                DiscoverViewModel(
                    discoverMovies: StubDiscoverMoviesUseCase(),
                    imageBaseURL: URL(fileURLWithPath: "/")
                )
            },
            makeSettingsViewModel: {
                SettingsViewModel(store: PreviewSettingsStore(), onSignOut: {}, isAuthenticated: { false })
            },
            makeTVDetailsViewModel: { showID in
                TVDetailsViewModel(
                    showID: showID,
                    fetchDetails: StubFetchTVDetailsUseCase(),
                    imageBaseURL: URL(fileURLWithPath: "/")
                )
            },
            makePersonViewModel: { personID in
                PersonViewModel(
                    personID: personID,
                    fetchDetails: StubFetchPersonDetailsUseCase(),
                    imageBaseURL: URL(fileURLWithPath: "/")
                )
            }
        )
    }

    /// Inert settings store for the preview.
    @MainActor
    private final class PreviewSettingsStore: SettingsStore {
        var theme: AppTheme = .system
        var language: AppLanguage = .english
        var appIcon: AppIcon = .default
        func clearCache() async {}
    }
#endif
