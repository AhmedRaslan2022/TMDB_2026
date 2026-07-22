//
//  DebugSmokeCheck.swift
//  TMDB
//
//  Created by Ahmed Raslan on 15/07/2026.
//

#if DEBUG
    import CoreEnvironment
    import CoreUtilities
    import Networking

    /// Launch-time wiring check, debug builds only: a TMDB `/configuration`
    /// call (Sprint 0). The Sprint 1 keychain roundtrip was removed once real
    /// session persistence (task 2.5) took over that path — and because it
    /// wrote to `.sessionID`, which now collides with launch session restore.
    enum DebugSmokeCheck {
        private struct ConfigurationEndpoint: Endpoint {
            let path = "/configuration"
        }

        static func run(apiClient: any APIClient, environment: AppEnvironment) async {
            let logger = AppLogger(category: "SmokeCheck")

            do {
                try await apiClient.sendRaw(ConfigurationEndpoint())
                logger.info("/configuration → 200 OK (env: \(environment.name.rawValue))")
            } catch APIError.unauthorized {
                logger.error("/configuration → 401. Is the real v4 token in Configs/Secrets.xcconfig?")
            } catch {
                logger.error("/configuration failed: \(error)")
            }
        }
    }
#endif
