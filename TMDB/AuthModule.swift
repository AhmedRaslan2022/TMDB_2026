//
//  AuthModule.swift
//  TMDB
//
//  Created by Ahmed Raslan on 17/07/2026.
//

import FeatureAuth

/// The app's auth composition: the concrete use cases and session store wired
/// once in `AppContainer`, plus the small helpers the coordinator needs to
/// drive the root switch. Keeps auth wiring out of `AppCoordinator`, which
/// stays navigation-focused.
@MainActor
struct AuthModule {
    let loginUseCase: any LoginUseCase
    let guestUseCase: any CreateGuestSessionUseCase
    let logoutUseCase: any LogoutUseCase
    let sessionRepository: any SessionRepository

    /// Builds the auth-screen view model, routing a completed session to
    /// `onAuthenticated` (the coordinator's root switch).
    func makeAuthViewModel(onAuthenticated: @escaping @MainActor (AuthSession) -> Void) -> AuthViewModel {
        AuthViewModel(
            loginUseCase: loginUseCase,
            createGuestSessionUseCase: guestUseCase,
            onAuthenticated: onAuthenticated
        )
    }

    /// Whether a session persists from a previous launch. A read failure is
    /// treated as "no session" — the user simply signs in again.
    func hasPersistedSession() async -> Bool {
        // `try?` yields a double optional; the outer nil means the read
        // failed, the inner nil means no session — both are "not signed in".
        guard let session = try? await sessionRepository.currentSession() else {
            return false
        }
        return session != nil
    }

    /// Ends the session: remote invalidation + local wipe (see `LogoutUseCase`).
    func logOut() async throws {
        try await logoutUseCase.execute()
    }
}

#if DEBUG
    extension AuthModule {
        /// Inert module — no network, no keychain — for SwiftUI previews and
        /// UI tests. `currentSession` returns nil so the auth gate shows on
        /// launch; the guest path returns a fake session so a UI test can
        /// enter the shell offline.
        static var stub: AuthModule {
            AuthModule(
                loginUseCase: PreviewAuthUseCase(),
                guestUseCase: PreviewAuthUseCase(),
                logoutUseCase: PreviewLogoutUseCase(),
                sessionRepository: PreviewSessionRepository()
            )
        }
    }

    private struct PreviewAuthUseCase: LoginUseCase, CreateGuestSessionUseCase {
        func execute() async throws -> AuthSession {
            .guest(sessionID: "preview")
        }
    }

    private struct PreviewLogoutUseCase: LogoutUseCase {
        func execute() async throws {}
    }

    private struct PreviewSessionRepository: SessionRepository {
        func currentSession() async throws -> AuthSession? {
            nil
        }

        func save(_: AuthSession) async throws {}
        func clearSession() async throws {}
    }
#endif
