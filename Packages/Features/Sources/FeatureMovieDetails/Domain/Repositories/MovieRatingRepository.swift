//
//  MovieRatingRepository.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

/// The user's personal rating for a movie, backed by TMDB's rating endpoints.
///
/// Unlike favorites/watchlist, rating has a single in-package consumer (the
/// details view model), so it's a Domain repository the view model depends on
/// directly — no cross-feature port/adapter is needed. Ratings are session
/// scoped: the implementation resolves the session through
/// `MovieRatingSessionProviding`.
public protocol MovieRatingRepository: Sendable {
    /// The signed-in user's rating for this movie (0.5–10 in 0.5 steps), or
    /// `nil` when unrated or no session exists. Throws on transport failures.
    func rating(movieID: Int) async throws -> Double?

    /// Sets the user's rating, or clears it when `value` is `nil`. Throws so the
    /// caller can roll back an optimistic UI: `MovieRatingError.notAuthenticated`
    /// when there's no session, or the transport error on a failed write.
    func setRating(_ value: Double?, movieID: Int) async throws
}

/// Failures surfaced by `MovieRatingRepository`.
public enum MovieRatingError: Error, Equatable {
    /// No TMDB session is available, so a rating can't be written.
    case notAuthenticated
}
