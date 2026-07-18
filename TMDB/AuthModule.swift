//
//  AuthModule.swift
//  TMDB
//
//  Created by Ahmed Raslan on 17/07/2026.
//

import FeatureAuth

/// Serializes logout teardown against new session creation: a login or guest
/// attempt started while teardown is still running waits for it first, so the
/// teardown's keychain wipe can never clobber a freshly saved session.
@MainActor
final class AuthTeardownBarrier {
    private var teardown: Task<Void, Never>?

    func begin(_ task: Task<Void, Never>) {
        teardown = task
    }

    func awaitTeardown() async {
        // Deliberately not nil-ed after awaiting: awaiting a finished task is
        // free, and clearing here could drop a teardown registered while this
        // caller was suspended.
        await teardown?.value
    }
}

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
    private let barrier = AuthTeardownBarrier()

    /// Builds the auth-screen view model, routing a completed session to
    /// `onAuthenticated` (the coordinator's root switch). Both use cases are
    /// wrapped so a new session waits for any in-flight logout teardown.
    func makeAuthViewModel(onAuthenticated: @escaping @MainActor (AuthSession) -> Void) -> AuthViewModel {
        AuthViewModel(
            loginUseCase: TeardownAwaitingLoginUseCase(base: loginUseCase, barrier: barrier),
            createGuestSessionUseCase: TeardownAwaitingGuestUseCase(base: guestUseCase, barrier: barrier),
            onAuthenticated: onAuthenticated
        )
    }

    /// Whether a session persists from a previous launch. `try?` flattens the
    /// optional (SE-0230), so a read failure and "no session" both come out
    /// nil — either way the user simply signs in again.
    func hasPersistedSession() async -> Bool {
        await (try? sessionRepository.currentSession()) != nil
    }

    /// Starts logout teardown (local wipe first, then remote delete) in the
    /// background and registers it with the barrier. Failures are reported,
    /// not thrown — the user is already logged out on-device.
    func beginLogout(onError: @escaping @MainActor (Error) -> Void) {
        let logoutUseCase = logoutUseCase
        barrier.begin(Task {
            do {
                try await logoutUseCase.execute()
            } catch {
                onError(error)
            }
        })
    }
}

private struct TeardownAwaitingLoginUseCase: LoginUseCase {
    let base: any LoginUseCase
    let barrier: AuthTeardownBarrier

    func execute() async throws -> AuthSession {
        await barrier.awaitTeardown()
        return try await base.execute()
    }
}

private struct TeardownAwaitingGuestUseCase: CreateGuestSessionUseCase {
    let base: any CreateGuestSessionUseCase
    let barrier: AuthTeardownBarrier

    func execute() async throws -> AuthSession {
        await barrier.awaitTeardown()
        return try await base.execute()
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
