//
//  AppContainer.swift
//  TMDB
//
//  Created by Ahmed Raslan on 15/07/2026.
//

import CoreEnvironment
import CoreModels
import CoreUI
import CoreUtilities
import FeatureAuth
import FeatureFavorites
import FeatureHome
import FeatureMovieDetails
import FeatureOnboarding
import FeatureProfile
import FeatureSearch
import FeatureTV
import Foundation
import KeychainStorage
import Networking
import SwiftData
import SwiftDataStorage
import UserDefaultsStorage

/// Composition root for the whole app.
///
/// DI approach (decided in Sprint 0): protocol-based constructor injection.
/// This container is the only place concrete types are chosen; everything
/// downstream — coordinators, use cases, repositories, view models — receives
/// protocol dependencies through initializers. No service locator, no
/// third-party DI framework, no singletons.
@MainActor
final class AppContainer {
    /// Build-time environment (name, base URLs, credentials).
    let environment: AppEnvironment
    /// Authenticated TMDB API client shared by all repositories.
    let apiClient: any APIClient
    /// Credential store backing session persistence.
    let secureStorage: any SecureStorage
    /// SwiftData container for app data (favorites, recents, cache).
    let modelContainer: ModelContainer
    /// Poster/backdrop cache, injected into the view environment at the root
    /// so every screen shares one memory layer and in-flight coalescing.
    let imageCache = ImageCache()
    /// Auth use cases + session store, composed once here.
    let authModule: AuthModule
    /// Offline-first favorites store (local SwiftData + best-effort TMDB sync).
    let favoritesRepository: any FavoritesRepository
    /// Offline-first watchlist store — reuses the favorites collection engine.
    let watchlistRepository: any WatchlistRepository
    /// App-wide preferences (theme, content language); observed by the root to
    /// apply the theme and read by the API client's language interceptor.
    let appSettings: AppSettings
    /// Root coordinator, composed with the auth module so navigation stays
    /// decoupled from concrete auth types.
    let coordinator: AppCoordinator

    init() {
        let environment = AppEnvironment.load()
        self.environment = environment
        let secureStorage = KeychainManager()
        self.secureStorage = secureStorage
        do {
            // The Test environment never persists to disk.
            modelContainer = try ModelContainerFactory.make(inMemory: environment.name == .test)
        } catch {
            preconditionFailure("Could not create ModelContainer: \(error)")
        }
        let appSettings = AppSettings(
            defaults: UserDefaultsManager(),
            imageCache: imageCache,
            modelContainer: modelContainer,
            iconController: AppIconController()
        )
        self.appSettings = appSettings
        let apiClient = Self.makeAPIClient(environment: environment, appSettings: appSettings)
        self.apiClient = apiClient

        authModule = Self.makeAuthModule(
            apiClient: apiClient,
            secureStorage: secureStorage,
            modelContainer: modelContainer
        )
        let accountProvider = AppFavoritesAccountProvider(secureStorage: secureStorage)
        favoritesRepository = FavoritesRepositoryImpl(
            modelContainer: modelContainer,
            apiClient: apiClient,
            accountProvider: accountProvider
        )
        watchlistRepository = WatchlistRepositoryImpl(
            modelContainer: modelContainer,
            apiClient: apiClient,
            accountProvider: accountProvider
        )
        coordinator = AppCoordinator(auth: authModule)
    }
}

// MARK: - Launch & onboarding

extension AppContainer {
    /// The launch decision (onboarding / auth / main). Reads the onboarding
    /// flag and the persisted session. In UI tests (offline stubs) onboarding
    /// is treated as complete so the existing flows reach the auth gate.
    var launchUseCase: any LaunchUseCase {
        #if DEBUG
            let onboardingComplete: @MainActor () -> Bool = UITestStubs.isActive
                ? { true }
                : { [appSettings] in appSettings.hasCompletedOnboarding }
        #else
            let onboardingComplete: @MainActor () -> Bool = { [appSettings] in appSettings.hasCompletedOnboarding }
        #endif
        return LaunchUseCaseImpl(
            hasCompletedOnboarding: onboardingComplete,
            hasSession: { [authModule] in await authModule.hasPersistedSession() }
        )
    }

    /// Builds the onboarding screen's view model, wiring completion to persist
    /// the "seen" flag and advance the root scene past onboarding.
    func makeOnboardingViewModel() -> OnboardingViewModel {
        OnboardingViewModel(
            completion: OnboardingCompletionAdapter { [appSettings, coordinator] in
                appSettings.hasCompletedOnboarding = true
                coordinator.completeOnboarding()
            }
        )
    }
}

/// Adapts the feature's `OnboardingCompletion` port to a composition-root
/// closure (persist the flag + route), so the package never touches storage
/// or navigation.
private struct OnboardingCompletionAdapter: OnboardingCompletion {
    let onComplete: @MainActor () -> Void
    func completeOnboarding() {
        onComplete()
    }
}

// MARK: - Screen view-model factories

extension AppContainer {
    /// Builds the Home screen's view model. Screen-scoped, so a factory
    /// rather than a stored property — each shell gets a fresh one.
    func makeHomeViewModel() -> HomeViewModel {
        #if DEBUG
            if UITestStubs.isActive {
                return HomeViewModel(
                    fetchMovieList: StubFetchMovieListUseCase(),
                    imageBaseURL: environment.imageBaseURL
                )
            }
        #endif
        return HomeViewModel(
            fetchMovieList: FetchMovieListUseCaseImpl(
                repository: MovieListRepositoryImpl(apiClient: apiClient)
            ),
            imageBaseURL: environment.imageBaseURL
        )
    }

    /// Builds a paginated "see all" view model for one home section. Called
    /// per push — each pushed list owns its own pagination state.
    func makeMovieListViewModel(section: HomeSection, window: TrendingWindow) -> MovieListViewModel {
        #if DEBUG
            if UITestStubs.isActive {
                return MovieListViewModel(
                    section: section,
                    window: window,
                    fetchMovieList: StubFetchMovieListUseCase(),
                    imageBaseURL: environment.imageBaseURL
                )
            }
        #endif
        return MovieListViewModel(
            section: section,
            window: window,
            fetchMovieList: FetchMovieListUseCaseImpl(
                repository: MovieListRepositoryImpl(apiClient: apiClient)
            ),
            imageBaseURL: environment.imageBaseURL
        )
    }

    /// Builds the Search screen's view model. Screen-scoped, one per shell.
    func makeSearchViewModel() -> SearchViewModel {
        #if DEBUG
            if UITestStubs.isActive {
                return SearchViewModel(
                    searchMovies: StubSearchMoviesUseCase(),
                    recentSearches: StubRecentSearchesRepository(),
                    imageBaseURL: environment.imageBaseURL
                )
            }
        #endif
        return SearchViewModel(
            searchMovies: SearchMoviesUseCaseImpl(
                repository: MovieSearchRepositoryImpl(apiClient: apiClient)
            ),
            recentSearches: RecentSearchesRepositoryImpl(modelContainer: modelContainer),
            imageBaseURL: environment.imageBaseURL
        )
    }

    /// Builds the Discover (advanced-search) view model. Called per push —
    /// each pushed Discover screen owns its own filter + pagination state.
    func makeDiscoverViewModel() -> DiscoverViewModel {
        #if DEBUG
            if UITestStubs.isActive {
                return DiscoverViewModel(
                    discoverMovies: StubDiscoverMoviesUseCase(),
                    imageBaseURL: environment.imageBaseURL
                )
            }
        #endif
        return DiscoverViewModel(
            discoverMovies: DiscoverMoviesUseCaseImpl(
                repository: DiscoverRepositoryImpl(apiClient: apiClient)
            ),
            imageBaseURL: environment.imageBaseURL
        )
    }

    /// Builds the Profile screen's view model. Screen-scoped, one per shell.
    func makeProfileViewModel() -> ProfileViewModel {
        #if DEBUG
            if UITestStubs.isActive {
                return ProfileViewModel(
                    repository: StubProfileRepository(),
                    imageBaseURL: environment.imageBaseURL
                )
            }
        #endif
        return ProfileViewModel(
            repository: ProfileRepositoryImpl(apiClient: apiClient, secureStorage: secureStorage),
            imageBaseURL: environment.imageBaseURL
        )
    }

    /// Builds the Settings screen's view model over the shared `appSettings`
    /// store, so theme changes made here are reflected at the app root.
    func makeSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel(
            store: appSettings,
            onSignOut: { [coordinator] in coordinator.signOut() },
            // Guest and signed-out both read false, so Settings offers a green
            // "Sign In" instead of "Sign Out" for them.
            isAuthenticated: { [authModule] in await authModule.isAuthenticated() }
        )
    }

    /// The environment name shown as a debug badge on the profile.
    var debugEnvironmentName: String? {
        #if DEBUG
            environment.name.rawValue.capitalized
        #else
            nil
        #endif
    }

    /// Builds the Favorites screen's view model. Screen-scoped, one per shell.
    func makeFavoritesViewModel() -> FavoritesViewModel {
        #if DEBUG
            if UITestStubs.isActive {
                return FavoritesViewModel(
                    repository: StubFavoritesRepository.shared,
                    imageBaseURL: environment.imageBaseURL
                )
            }
        #endif
        return FavoritesViewModel(repository: favoritesRepository, imageBaseURL: environment.imageBaseURL)
    }

    /// Builds a movie-details view model. Called per push — each pushed
    /// details screen owns its own fetch state.
    func makeMovieDetailsViewModel(movieID: Int) -> MovieDetailsViewModel {
        #if DEBUG
            if UITestStubs.isActive {
                return MovieDetailsViewModel(
                    movieID: movieID,
                    fetchDetails: StubFetchMovieDetailsUseCase(),
                    favorites: StubFavoriteToggling(),
                    watchlist: StubWatchlistToggling(),
                    rating: StubMovieRatingRepository(),
                    imageBaseURL: environment.imageBaseURL
                )
            }
        #endif
        return MovieDetailsViewModel(
            movieID: movieID,
            fetchDetails: FetchMovieDetailsUseCaseImpl(
                repository: MovieDetailsRepositoryImpl(apiClient: apiClient)
            ),
            favorites: FavoritesToggleAdapter(repository: favoritesRepository),
            watchlist: WatchlistToggleAdapter(repository: watchlistRepository),
            rating: MovieRatingRepositoryImpl(
                apiClient: apiClient,
                sessionProvider: AppRatingSessionProvider(secureStorage: secureStorage)
            ),
            imageBaseURL: environment.imageBaseURL
        )
    }
}
