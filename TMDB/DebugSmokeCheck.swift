#if DEBUG
    import CoreEnvironment
    import CoreNetworking
    import CoreUtilities
    import Foundation

    /// Sprint 0 wiring check: calls TMDB `/configuration` once at launch and logs
    /// the outcome. Debug builds only; removed when real features land.
    enum DebugSmokeCheck {
        private struct ConfigurationEndpoint: Endpoint {
            let path = "/configuration"
        }

        static func run() async {
            let logger = AppLogger(category: "SmokeCheck")
            let environment = AppEnvironment.load()
            let client = URLSessionAPIClient(
                baseURL: environment.apiBaseURL,
                interceptors: [BearerAuthInterceptor(tokenProvider: { environment.accessToken })]
            )

            do {
                try await client.sendRaw(ConfigurationEndpoint())
                logger.info("/configuration → 200 OK (env: \(environment.name.rawValue))")
            } catch APIError.unauthorized {
                logger.error("/configuration → 401. Is the real v4 token in Configs/Secrets.xcconfig?")
            } catch {
                logger.error("/configuration failed: \(error)")
            }
        }
    }
#endif
