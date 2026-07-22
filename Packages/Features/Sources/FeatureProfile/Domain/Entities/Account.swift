//
//  Account.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

/// The signed-in TMDB account. Feature-local: only Profile consumes it.
public struct Account: Equatable, Sendable, Identifiable {
    public let id: Int
    public let username: String
    /// Display name; TMDB often returns an empty string, normalized to nil.
    public let name: String?
    /// TMDB-hosted avatar path (e.g. `/abc.jpg`), resolved by presentation.
    public let avatarPath: String?
    /// Gravatar hash, the fallback avatar when there's no TMDB avatar.
    public let gravatarHash: String?

    public init(id: Int, username: String, name: String? = nil, avatarPath: String? = nil, gravatarHash: String? = nil) {
        self.id = id
        self.username = username
        self.name = name
        self.avatarPath = avatarPath
        self.gravatarHash = gravatarHash
    }
}
