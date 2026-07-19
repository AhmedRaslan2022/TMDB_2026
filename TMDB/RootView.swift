//
//  RootView.swift
//  TMDB
//
//  Created by Ahmed Raslan on 15/07/2026.
//

import CoreModels
import FeatureAuth
import FeatureHome
import FeatureMovieDetails
import FeatureProfile
import FeatureSearch
import SwiftUI

/// Root switch between the auth gate and the main shell, driven entirely by
/// `AppCoordinator`. Modal presentation is attached here so any scene can
/// present coordinator-owned sheets and covers. Screen view models are built
/// once from the container and held in `@State` so scene switches don't
/// reset their loading/error state.
struct RootView: View {
    @Bindable private var coordinator: AppCoordinator
    @State private var authViewModel: AuthViewModel
    @State private var homeViewModel: HomeViewModel
    @State private var searchViewModel: SearchViewModel
    private let makeMovieListViewModel: @MainActor (HomeSection, TrendingWindow) -> MovieListViewModel
    private let makeMovieDetailsViewModel: @MainActor (Int) -> MovieDetailsViewModel

    init(container: AppContainer) {
        _coordinator = Bindable(container.coordinator)
        _authViewModel = State(initialValue: container.coordinator.makeAuthViewModel())
        _homeViewModel = State(initialValue: container.makeHomeViewModel())
        _searchViewModel = State(initialValue: container.makeSearchViewModel())
        makeMovieListViewModel = container.makeMovieListViewModel
        makeMovieDetailsViewModel = container.makeMovieDetailsViewModel
    }

    var body: some View {
        content
            .task { await coordinator.restoreSession() }
            .sheet(item: $coordinator.presentedSheet) { sheet in
                switch sheet {
                case .about:
                    AboutSheetView(onDismiss: { coordinator.dismissModal() })
                }
            }
            .fullScreenCover(item: $coordinator.presentedFullScreenCover) { cover in
                switch cover {
                case .whatsNew:
                    WhatsNewCoverView(onDismiss: { coordinator.dismissModal() })
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        switch coordinator.rootScene {
        case .auth:
            AuthView(viewModel: authViewModel)
        case .main:
            MainTabView(
                coordinator: coordinator,
                homeViewModel: homeViewModel,
                searchViewModel: searchViewModel,
                makeMovieListViewModel: makeMovieListViewModel,
                makeMovieDetailsViewModel: makeMovieDetailsViewModel
            )
        }
    }
}

#if DEBUG
    #Preview {
        RootView(container: AppContainer())
    }
#endif
