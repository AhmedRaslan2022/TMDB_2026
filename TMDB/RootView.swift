//
//  RootView.swift
//  TMDB
//
//  Created by Ahmed Raslan on 15/07/2026.
//

import CoreModels
import FeatureAuth
import FeatureFavorites
import FeatureHome
import FeatureMovieDetails
import FeatureOnboarding
import FeaturePerson
import FeatureProfile
import FeatureSearch
import FeatureTV
import SwiftUI

/// Root switch between the auth gate and the main shell, driven entirely by
/// `AppCoordinator`. Modal presentation is attached here so any scene can
/// present coordinator-owned sheets and covers. Screen view models are built
/// once from the container and held in `@State` so scene switches don't
/// reset their loading/error state.
struct RootView: View {
    @Bindable private var coordinator: AppCoordinator
    @State private var authViewModel: AuthViewModel
    @State private var onboardingViewModel: OnboardingViewModel
    private let launchUseCase: any LaunchUseCase
    @State private var homeViewModel: HomeViewModel
    @State private var tvHomeViewModel: TVHomeViewModel
    @State private var searchViewModel: SearchViewModel
    @State private var favoritesViewModel: FavoritesViewModel
    @State private var profileViewModel: ProfileViewModel
    private let debugEnvironmentName: String?
    private let makeMovieListViewModel: @MainActor (HomeSection, TrendingWindow) -> MovieListViewModel
    private let makeMovieDetailsViewModel: @MainActor (Int) -> MovieDetailsViewModel
    private let makeDiscoverViewModel: @MainActor () -> DiscoverViewModel
    private let makeSettingsViewModel: @MainActor () -> SettingsViewModel
    private let makeTVDetailsViewModel: @MainActor (Int) -> TVDetailsViewModel
    private let makePersonViewModel: @MainActor (Int) -> PersonViewModel
    private let appSettings: AppSettings

    init(container: AppContainer) {
        _coordinator = Bindable(container.coordinator)
        _authViewModel = State(initialValue: container.coordinator.makeAuthViewModel())
        _onboardingViewModel = State(initialValue: container.makeOnboardingViewModel())
        launchUseCase = container.launchUseCase
        _homeViewModel = State(initialValue: container.makeHomeViewModel())
        _tvHomeViewModel = State(initialValue: container.makeTVHomeViewModel())
        _searchViewModel = State(initialValue: container.makeSearchViewModel())
        _favoritesViewModel = State(initialValue: container.makeFavoritesViewModel())
        _profileViewModel = State(initialValue: container.makeProfileViewModel())
        debugEnvironmentName = container.debugEnvironmentName
        makeMovieListViewModel = container.makeMovieListViewModel
        makeMovieDetailsViewModel = container.makeMovieDetailsViewModel
        makeDiscoverViewModel = container.makeDiscoverViewModel
        makeSettingsViewModel = container.makeSettingsViewModel
        makeTVDetailsViewModel = container.makeTVDetailsViewModel
        makePersonViewModel = container.makePersonViewModel
        appSettings = container.appSettings
    }

    var body: some View {
        content
            // Content language also drives the UI: render in that locale (live
            // string localization) and mirror to RTL for Arabic. The `.id`
            // rebuilds the whole shell on a language change — the tab bar and
            // stacks are torn down and recreated so the mirroring applies
            // cleanly rather than half-updating an existing layout.
            .environment(\.locale, appSettings.language.locale)
            .environment(\.layoutDirection, appSettings.language.layoutDirection)
            .id(appSettings.language)
            .preferredColorScheme(appSettings.theme.colorScheme)
            .onOpenURL { coordinator.handle(url: $0) }
            .task { await coordinator.start(using: launchUseCase) }
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
        case .splash:
            SplashView()
        case .onboarding:
            OnboardingView(viewModel: onboardingViewModel)
        case .auth:
            AuthView(viewModel: authViewModel)
        case .main:
            MainTabView(
                coordinator: coordinator,
                homeViewModel: homeViewModel,
                tvHomeViewModel: tvHomeViewModel,
                searchViewModel: searchViewModel,
                favoritesViewModel: favoritesViewModel,
                profileViewModel: profileViewModel,
                debugEnvironmentName: debugEnvironmentName,
                makeMovieListViewModel: makeMovieListViewModel,
                makeMovieDetailsViewModel: makeMovieDetailsViewModel,
                makeDiscoverViewModel: makeDiscoverViewModel,
                makeSettingsViewModel: makeSettingsViewModel,
                makeTVDetailsViewModel: makeTVDetailsViewModel,
                makePersonViewModel: makePersonViewModel
            )
        }
    }
}

#if DEBUG
    #Preview {
        RootView(container: AppContainer())
    }
#endif
