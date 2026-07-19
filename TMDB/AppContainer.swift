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
import FeatureHome
import Foundation
import KeychainStorage
import Networking
import SwiftData
import SwiftDataStorage

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
    /// Root coordinator, composed with the auth module so navigation stays
    /// decoupled from concrete auth types.
    let coordinator: AppCoordinator

    init() {
        let environment = AppEnvironment.load()
        self.environment = environment
        let apiClient = URLSessionAPIClient(
            baseURL: environment.apiBaseURL,
            interceptors: [
                BearerAuthInterceptor(tokenProvider: { environment.accessToken }),
            ]
        )
        self.apiClient = apiClient
        let secureStorage = KeychainManager()
        self.secureStorage = secureStorage
        do {
            // The Test environment never persists to disk.
            modelContainer = try ModelContainerFactory.make(inMemory: environment.name == .test)
        } catch {
            preconditionFailure("Could not create ModelContainer: \(error)")
        }

        authModule = Self.makeAuthModule(
            apiClient: apiClient,
            secureStorage: secureStorage,
            modelContainer: modelContainer
        )
        coordinator = AppCoordinator(auth: authModule)
    }

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

    /// Composes the auth vertical. In DEBUG a launch argument swaps in the
    /// inert stub so UI tests — which can't complete real TMDB web auth —
    /// exercise the shell offline.
    private static func makeAuthModule(
        apiClient: any APIClient,
        secureStorage: any SecureStorage,
        modelContainer: ModelContainer
    ) -> AuthModule {
        #if DEBUG
            // UI tests can't complete real TMDB auth, so they opt into the
            // inert stub before any live collaborators are built.
            if UITestStubs.isActive {
                return .stub
            }
        #endif
        let authRepository = AuthRepositoryImpl(apiClient: apiClient)
        let sessionRepository = SessionRepositoryImpl(secureStorage: secureStorage)
        return AuthModule(
            loginUseCase: LoginUseCaseImpl(
                authRepository: authRepository,
                sessionRepository: sessionRepository,
                authorizer: WebRequestTokenAuthorizer()
            ),
            guestUseCase: CreateGuestSessionUseCaseImpl(
                authRepository: authRepository,
                sessionRepository: sessionRepository
            ),
            logoutUseCase: LogoutUseCaseImpl(
                authRepository: authRepository,
                sessionRepository: sessionRepository,
                userDataStore: SwiftDataUserStore(modelContainer: modelContainer)
            ),
            sessionRepository: sessionRepository
        )
    }
}
