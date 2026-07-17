//
//  AuthDTOMappers.swift
//  TMDB
//
//  Created by Ahmed Raslan on 17/07/2026.
//

import Foundation

/// Data-layer mapping failures, kept separate from `AuthError` (user-facing
/// flow outcomes) and `APIError` (transport).
enum AuthDataError: Error, Equatable {
    /// TMDB returned an expiry timestamp in an unrecognised format.
    case invalidExpiryDate(String)
}

extension RequestTokenDTO {
    func toDomain() throws -> RequestToken {
        guard let expiresAt = TMDBDateParser.parse(expiresAt) else {
            throw AuthDataError.invalidExpiryDate(expiresAt)
        }
        return RequestToken(value: requestToken, expiresAt: expiresAt)
    }
}

extension CreateSessionDTO {
    func toDomain() -> AuthSession {
        .authenticated(sessionID: sessionId)
    }
}

extension GuestSessionDTO {
    func toDomain() -> AuthSession {
        // Guest expiry is deliberately dropped: launch validation (2.5) asks
        // the API instead of trusting a stored date.
        .guest(sessionID: guestSessionId)
    }
}

/// Parses TMDB's `"yyyy-MM-dd HH:mm:ss UTC"` timestamps.
enum TMDBDateParser {
    static func parse(_ string: String) -> Date? {
        // Built per call: DateFormatter is not Sendable, and auth calls are
        // far too rare for formatter reuse to matter.
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss 'UTC'"
        return formatter.date(from: string)
    }
}
