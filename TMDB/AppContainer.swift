// By Ahmed Raslan ®

import CoreEnvironment
import CoreStorage
import CoreUtilities
import Networking
import SwiftData

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

    init() {
        let environment = AppEnvironment.load()
        self.environment = environment
        apiClient = URLSessionAPIClient(
            baseURL: environment.apiBaseURL,
            interceptors: [
                BearerAuthInterceptor(tokenProvider: { environment.accessToken }),
            ]
        )
        secureStorage = KeychainManager()
        do {
            // The Test environment never persists to disk.
            modelContainer = try ModelContainerFactory.make(inMemory: environment.name == .test)
        } catch {
            preconditionFailure("Could not create ModelContainer: \(error)")
        }
    }
}
