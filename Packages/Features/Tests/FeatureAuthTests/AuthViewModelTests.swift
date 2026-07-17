//
//  AuthViewModelTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 17/07/2026.
//

import Foundation
import Testing
@testable import FeatureAuth

@MainActor
@Suite("AuthViewModel")
struct AuthViewModelTests {
    private let loginUseCase = AuthUseCaseMock()
    private let guestUseCase = AuthUseCaseMock()

    /// Sessions handed to `onAuthenticated`, captured for assertions.
    private final class Captured {
        var sessions: [AuthSession] = []
    }

    private let captured = Captured()

    private func makeViewModel() -> AuthViewModel {
        let captured = captured
        return AuthViewModel(
            loginUseCase: loginUseCase,
            createGuestSessionUseCase: guestUseCase,
            onAuthenticated: { captured.sessions.append($0) }
        )
    }

    @Test("initial state is idle")
    func initialState() {
        #expect(makeViewModel().state == .idle)
    }

    @Test("successful login: state becomes loaded and the session is handed off")
    func loginSuccess() async {
        loginUseCase.result = .success(.authenticated(sessionID: "session-1"))
        let viewModel = makeViewModel()

        await viewModel.logIn()

        #expect(viewModel.state == .loaded)
        #expect(captured.sessions == [.authenticated(sessionID: "session-1")])
    }

    @Test("cancelled approval returns to idle without reporting an error or a session")
    func loginUserCancelled() async {
        loginUseCase.result = .failure(AuthError.userCancelled)
        let viewModel = makeViewModel()

        await viewModel.logIn()

        #expect(viewModel.state == .idle)
        #expect(captured.sessions.isEmpty)
    }

    @Test("task cancellation returns to idle, not error")
    func loginTaskCancelled() async {
        loginUseCase.result = .failure(CancellationError())
        let viewModel = makeViewModel()

        await viewModel.logIn()

        #expect(viewModel.state == .idle)
    }

    @Test("unapproved token surfaces the not-approved message")
    func loginTokenNotApproved() async {
        loginUseCase.result = .failure(AuthError.tokenNotApproved)
        let viewModel = makeViewModel()

        await viewModel.logIn()

        guard case let .error(message) = viewModel.state else {
            Issue.record("expected error state, got \(viewModel.state)")
            return
        }
        #expect(message.key == "auth.error.notApproved")
        #expect(captured.sessions.isEmpty)
    }

    @Test("an unexpected error surfaces the generic message")
    func loginGenericError() async {
        loginUseCase.result = .failure(MockError.stubbed)
        let viewModel = makeViewModel()

        await viewModel.logIn()

        guard case let .error(message) = viewModel.state else {
            Issue.record("expected error state, got \(viewModel.state)")
            return
        }
        #expect(message.key == "auth.error.generic")
    }

    @Test("guest path: state becomes loaded and the guest session is handed off")
    func guestSuccess() async {
        guestUseCase.result = .success(.guest(sessionID: "guest-1"))
        let viewModel = makeViewModel()

        await viewModel.continueAsGuest()

        #expect(viewModel.state == .loaded)
        #expect(captured.sessions == [.guest(sessionID: "guest-1")])
    }

    @Test("guest path failure surfaces the generic message")
    func guestError() async {
        guestUseCase.result = .failure(MockError.stubbed)
        let viewModel = makeViewModel()

        await viewModel.continueAsGuest()

        guard case .error = viewModel.state else {
            Issue.record("expected error state, got \(viewModel.state)")
            return
        }
    }

    @Test("state is loading while a request is in flight")
    func loadingState() async {
        let gated = GatedAuthUseCaseMock()
        let viewModel = AuthViewModel(
            loginUseCase: gated,
            createGuestSessionUseCase: guestUseCase,
            onAuthenticated: { _ in }
        )

        let task = Task { await viewModel.logIn() }
        // Yield until the use case has suspended inside the gate.
        while gated.executeCallCount == 0 {
            await Task.yield()
        }

        #expect(viewModel.state == .loading)
        gated.release()
        await task.value
        #expect(viewModel.state == .loaded)
    }

    @Test("a second request while loading is ignored")
    func reentrancyGuard() async {
        let gated = GatedAuthUseCaseMock()
        let viewModel = AuthViewModel(
            loginUseCase: gated,
            createGuestSessionUseCase: guestUseCase,
            onAuthenticated: { _ in }
        )

        let first = Task { await viewModel.logIn() }
        while gated.executeCallCount == 0 {
            await Task.yield()
        }
        await viewModel.logIn() // returns immediately: guarded out

        #expect(gated.executeCallCount == 1)
        gated.release()
        await first.value
    }
}
