import CoreEnvironment
import CoreNetworking
import CoreUtilities

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

    init() {
        let environment = AppEnvironment.load()
        self.environment = environment
        apiClient = URLSessionAPIClient(
            baseURL: environment.apiBaseURL,
            interceptors: [
                BearerAuthInterceptor(tokenProvider: { environment.accessToken }),
            ]
        )
    }
}
