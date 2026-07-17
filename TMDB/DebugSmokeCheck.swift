//
//  DebugSmokeCheck.swift
//  TMDB
//
//  Created by Ahmed Raslan on 15/07/2026.
//

#if DEBUG
    import CoreEnvironment
    import CoreUtilities
    import Foundation
    import KeychainStorage
    import Networking

    /// Launch-time wiring checks, debug builds only: TMDB `/configuration`
    /// call (Sprint 0) and a keychain roundtrip (Sprint 1). Removed once real
    /// features cover these paths.
    enum DebugSmokeCheck {
        private struct ConfigurationEndpoint: Endpoint {
            let path = "/configuration"
        }

        static func run(
            apiClient: any APIClient,
            secureStorage: any SecureStorage,
            environment: AppEnvironment
        ) async {
            let logger = AppLogger(category: "SmokeCheck")

            do {
                try await apiClient.sendRaw(ConfigurationEndpoint())
                logger.info("/configuration → 200 OK (env: \(environment.name.rawValue))")
            } catch APIError.unauthorized {
                logger.error("/configuration → 401. Is the real v4 token in Configs/Secrets.xcconfig?")
            } catch {
                logger.error("/configuration failed: \(error)")
            }

            do {
                try await secureStorage.set("smoke-check", for: .sessionID)
                let read = try await secureStorage.string(for: .sessionID)
                try await secureStorage.removeValue(for: .sessionID)
                if read == "smoke-check" {
                    logger.info("keychain roundtrip OK")
                } else {
                    logger.error("keychain roundtrip mismatch: \(read ?? "nil")")
                }
            } catch {
                logger.error("keychain roundtrip failed: \(error)")
            }
        }
    }
#endif
