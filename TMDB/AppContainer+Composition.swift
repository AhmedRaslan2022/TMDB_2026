//
//  AppContainer+Composition.swift
//  TMDB
//
//  Created by Ahmed Raslan on 21/07/2026.
//

import CoreEnvironment
import FeatureAuth
import KeychainStorage
import Networking
import SwiftData
import SwiftDataStorage

/// Composition helpers split out of AppContainer.swift to keep it under the
/// file-length budget.
extension AppContainer {
    /// The authenticated TMDB client: a bearer token plus the language/region
    /// interceptor that localizes API content to the user's settings + device.
    /// In Dev/Test it's wrapped in `LoggingAPIClient` (request/response logging);
    /// Staging/Live get the bare client so nothing is logged in production.
    static func makeAPIClient(environment: AppEnvironment, appSettings: AppSettings) -> any APIClient {
        let client = URLSessionAPIClient(
            baseURL: environment.apiBaseURL,
            interceptors: [
                BearerAuthInterceptor(tokenProvider: { environment.accessToken }),
                LanguageQueryInterceptor(
                    languageProvider: appSettings.languageCodeProvider,
                    regionProvider: appSettings.regionCodeProvider
                ),
            ]
        )
        switch environment.name {
        case .dev, .test: return LoggingAPIClient(wrapping: client)
        case .staging, .live: return client
        }
    }

    /// Composes the auth vertical. In DEBUG a launch argument swaps in the
    /// inert stub so UI tests — which can't complete real TMDB web auth —
    /// exercise the shell offline.
    static func makeAuthModule(
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
