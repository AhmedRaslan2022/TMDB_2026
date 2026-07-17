//
//  AuthViewModel.swift
//  TMDB
//
//  Created by Ahmed Raslan on 17/07/2026.
//

import Foundation
import Observation

/// Drives the auth screen: TMDB account login (task 2.3 flow) and the guest
/// path (task 2.4). Owns no navigation — it reports a completed session
/// through `onAuthenticated`, which the coordinator turns into a root switch
/// (task 2.8).
@Observable
@MainActor
public final class AuthViewModel {
    /// Exhaustive screen state. `userCancelled` deliberately returns to
    /// `idle` rather than `error` — a dismissed approval sheet is not a
    /// failure to report.
    public enum ViewState: Equatable {
        /// Awaiting the user to pick account login or guest.
        case idle
        /// A login or guest request is in flight.
        case loading
        /// A session was established; handoff to the coordinator follows.
        case loaded
        /// The last attempt failed; message is user-facing.
        case error(LocalizedStringResource)
    }

    public private(set) var state: ViewState = .idle

    private let loginUseCase: any LoginUseCase
    private let createGuestSessionUseCase: any CreateGuestSessionUseCase
    private let onAuthenticated: @MainActor (AuthSession) -> Void

    /// - Parameter onAuthenticated: Called once a session exists (account or
    ///   guest). The coordinator uses it to leave the auth gate.
    public init(
        loginUseCase: any LoginUseCase,
        createGuestSessionUseCase: any CreateGuestSessionUseCase,
        onAuthenticated: @escaping @MainActor (AuthSession) -> Void
    ) {
        self.loginUseCase = loginUseCase
        self.createGuestSessionUseCase = createGuestSessionUseCase
        self.onAuthenticated = onAuthenticated
    }

    /// Runs the full TMDB account login flow.
    public func logIn() async {
        await run { try await loginUseCase.execute() }
    }

    /// Starts an anonymous guest session.
    public func continueAsGuest() async {
        await run { try await createGuestSessionUseCase.execute() }
    }

    private func run(_ operation: () async throws -> AuthSession) async {
        guard state != .loading else { return }
        state = .loading
        do {
            let session = try await operation()
            state = .loaded
            onAuthenticated(session)
        } catch is CancellationError {
            state = .idle
        } catch AuthError.userCancelled {
            state = .idle
        } catch {
            state = .error(Self.message(for: error))
        }
    }

    private static func message(for error: Error) -> LocalizedStringResource {
        switch error {
        case AuthError.tokenNotApproved:
            LocalizedStringResource(
                "auth.error.notApproved",
                defaultValue: "The sign-in wasn't approved. Please try again.",
                comment: "Shown when the user's TMDB request token was not approved"
            )
        default:
            LocalizedStringResource(
                "auth.error.generic",
                defaultValue: "Something went wrong. Please try again.",
                comment: "Generic auth failure message"
            )
        }
    }
}
