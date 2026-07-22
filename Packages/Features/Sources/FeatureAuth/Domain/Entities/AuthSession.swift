//
//  AuthSession.swift
//  TMDB
//
//  Created by Ahmed Raslan on 17/07/2026.
//

/// An active TMDB session, either tied to a user account or anonymous.
///
/// Guest expiry is not modelled: launch-time validation (task 2.5) asks the
/// API instead of trusting a stored date.
public enum AuthSession: Equatable, Sendable {
    /// A session backed by a logged-in TMDB account.
    case authenticated(sessionID: String)
    /// An anonymous guest session (can rate, cannot use account features).
    case guest(sessionID: String)

    /// The session identifier sent to authenticated endpoints.
    public var sessionID: String {
        switch self {
        case let .authenticated(sessionID), let .guest(sessionID):
            sessionID
        }
    }

    /// `true` for anonymous guest sessions.
    public var isGuest: Bool {
        if case .guest = self {
            true
        } else {
            false
        }
    }
}
