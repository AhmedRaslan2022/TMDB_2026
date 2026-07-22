//
//  AuthFlowCoordinationTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 18/07/2026.
//

import FeatureAuth
import Testing
@testable import TMDB

/// Coordinator-level auth behavior: launch restore, sign-out teardown, and
/// the barrier that keeps a logout wipe from clobbering a new session.
@MainActor
@Suite("Auth flow coordination")
struct AuthFlowCoordinationTests {
    /// Shared ordered record of use-case activity across mocks. `@MainActor`
    /// so appends from the mocks' isolated methods are race-free.
    @MainActor
    private final class EventLog {
        var events: [String] = []
    }

    private struct StubSessionRepository: SessionRepository {
        var stored: AuthSession?

        func currentSession() async throws -> AuthSession? {
            stored
        }

        func save(_: AuthSession) async throws {}
        func clearSession() async throws {}
    }

    @MainActor
    private final class RecordingLogoutUseCase: LogoutUseCase {
        let log: EventLog
        /// When true, `execute` suspends until `release()` is called.
        let gated: Bool
        private var continuation: CheckedContinuation<Void, Never>?

        init(log: EventLog, gated: Bool = false) {
            self.log = log
            self.gated = gated
        }

        func execute() async throws {
            log.events.append("logout-start")
            if gated {
                await withCheckedContinuation { continuation = $0 }
            }
            log.events.append("logout-end")
        }

        func release() {
            continuation?.resume()
            continuation = nil
        }
    }

    @MainActor
    private struct RecordingGuestUseCase: CreateGuestSessionUseCase {
        let log: EventLog

        func execute() async throws -> AuthSession {
            log.events.append("guest")
            return .guest(sessionID: "new-guest")
        }
    }

    private struct FailingLoginUseCase: LoginUseCase {
        func execute() async throws -> AuthSession {
            throw AuthError.userCancelled
        }
    }

    private func makeModule(
        stored: AuthSession? = nil,
        logout: RecordingLogoutUseCase,
        log: EventLog
    ) -> AuthModule {
        AuthModule(
            loginUseCase: FailingLoginUseCase(),
            guestUseCase: RecordingGuestUseCase(log: log),
            logoutUseCase: logout,
            sessionRepository: StubSessionRepository(stored: stored)
        )
    }

    @Test("restoreSession enters the main shell when a session persists")
    func restorePositive() async {
        let log = EventLog()
        let module = makeModule(stored: .authenticated(sessionID: "persisted"), logout: .init(log: log), log: log)
        let coordinator = AppCoordinator(auth: module)

        await coordinator.restoreSession()

        #expect(coordinator.rootScene == .main)
    }

    @Test("restoreSession stays on the auth gate when nothing persists")
    func restoreNegative() async {
        let log = EventLog()
        let coordinator = AppCoordinator(auth: makeModule(logout: .init(log: log), log: log))

        await coordinator.restoreSession()

        #expect(coordinator.rootScene == .auth)
    }

    @Test("signOut returns to the gate and runs logout teardown")
    func signOutRunsLogout() async {
        let log = EventLog()
        let logout = RecordingLogoutUseCase(log: log)
        let coordinator = AppCoordinator(auth: makeModule(logout: logout, log: log))
        coordinator.completeAuthGate()

        coordinator.signOut()

        #expect(coordinator.rootScene == .auth)
        // Bounded so a scheduling regression fails the test instead of
        // hanging the suite; the assertion below catches a timeout.
        for _ in 0 ..< 10000 where log.events.count < 2 {
            await Task.yield()
        }
        #expect(log.events == ["logout-start", "logout-end"])
    }

    @Test("a guest session started during logout teardown waits for the wipe to finish")
    func newSessionWaitsForTeardown() async throws {
        let log = EventLog()
        let logout = RecordingLogoutUseCase(log: log, gated: true)
        let module = makeModule(logout: logout, log: log)
        let coordinator = AppCoordinator(auth: module)
        let viewModel = module.makeAuthViewModel(onAuthenticated: { _ in })

        coordinator.signOut()
        for _ in 0 ..< 10000 where log.events.isEmpty {
            await Task.yield()
        }
        try #require(log.events == ["logout-start"]) // teardown is in flight

        let guestAttempt = Task { await viewModel.continueAsGuest() }
        // Give the guest attempt every chance to (incorrectly) run early.
        for _ in 0 ..< 20 {
            await Task.yield()
        }
        #expect(log.events == ["logout-start"], "guest must not run while teardown is gated")

        logout.release()
        await guestAttempt.value

        #expect(log.events == ["logout-start", "logout-end", "guest"])
        #expect(viewModel.state == .loaded)
    }
}
