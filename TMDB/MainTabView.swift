//
//  MainTabView.swift
//  TMDB
//
//  Created by Ahmed Raslan on 17/07/2026.
//

import FeatureFavorites
import FeatureHome
import FeatureProfile
import FeatureSearch
import SwiftUI

/// The main shell: four tabs, each owning a `NavigationStack` bound to its
/// child coordinator's path. All pushes go through the coordinators.
struct MainTabView: View {
    @Bindable var coordinator: AppCoordinator
    let homeViewModel: HomeViewModel

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
            RouteDestinations.attach(
                to: HomeView(
                    viewModel: homeViewModel,
                    onSelectMovie: { coordinator.home.push(.movieDetails(movieID: $0)) }
                )
            )
        }
    }

    private var searchTab: some View {
        @Bindable var search = coordinator.search
        return NavigationStack(path: $search.path) {
            RouteDestinations.attach(
                to: SearchView(onSelectMovie: { coordinator.search.push(.movieDetails(movieID: $0)) })
            )
        }
    }

    private var favoritesTab: some View {
        @Bindable var favorites = coordinator.favorites
        return NavigationStack(path: $favorites.path) {
            RouteDestinations.attach(
                to: FavoritesView(onSelectMovie: { coordinator.favorites.push(.movieDetails(movieID: $0)) })
            )
        }
    }

    private var profileTab: some View {
        @Bindable var profile = coordinator.profile
        return NavigationStack(path: $profile.path) {
            RouteDestinations.attach(
                to: ProfileView(
                    onOpenSettings: { coordinator.profile.push(.settings) },
                    onShowAbout: { coordinator.presentSheet(.about) },
                    onShowWhatsNew: { coordinator.presentFullScreenCover(.whatsNew) },
                    onSignOut: { coordinator.signOut() }
                )
            )
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
            )
        )
    }
#endif
