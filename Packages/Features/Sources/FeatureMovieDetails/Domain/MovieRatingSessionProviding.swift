//
//  MovieRatingSessionProviding.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

/// Supplies the active TMDB session id for rating writes — a port this feature
/// owns so it stays ignorant of the credential store. The composition root
/// adapts the Keychain-backed session to it. Guests and logged-out users
/// resolve to `nil`, at which point rating writes fail fast.
public protocol MovieRatingSessionProviding: Sendable {
    /// The active session id (user session), or `nil` when unavailable.
    func sessionID() async -> String?
}
