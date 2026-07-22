//
//  RequestToken.swift
//  TMDB
//
//  Created by Ahmed Raslan on 17/07/2026.
//

import Foundation

/// A short-lived TMDB request token. Created unapproved, then approved by the
/// user on TMDB's website before it can be exchanged for a session.
public struct RequestToken: Equatable, Sendable {
    /// The opaque token value TMDB issued.
    public let value: String
    /// When TMDB invalidates the token if it is not used.
    public let expiresAt: Date

    public init(value: String, expiresAt: Date) {
        self.value = value
        self.expiresAt = expiresAt
    }
}
