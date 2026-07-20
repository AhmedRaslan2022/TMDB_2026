//
//  MovieRatingRepositoryImpl.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

import Networking

/// `MovieRatingRepository` over TMDB's rating endpoints, resolving the session
/// through the injected `MovieRatingSessionProviding` port. No local cache:
/// TMDB's account state is the source of truth for a personal rating.
public struct MovieRatingRepositoryImpl: MovieRatingRepository {
    private let remote: any MovieRatingRemoteDataSource
    private let sessionProvider: any MovieRatingSessionProviding

    /// Composition-root entry point.
    public init(apiClient: any APIClient, sessionProvider: any MovieRatingSessionProviding) {
        self.init(
            remote: MovieRatingRemoteDataSourceImpl(apiClient: apiClient),
            sessionProvider: sessionProvider
        )
    }

    init(remote: any MovieRatingRemoteDataSource, sessionProvider: any MovieRatingSessionProviding) {
        self.remote = remote
        self.sessionProvider = sessionProvider
    }

    public func rating(movieID: Int) async throws -> Double? {
        // No session ⇒ nothing to read; a rating is a per-account concept.
        guard let sessionID = await sessionProvider.sessionID() else { return nil }
        return try await remote.rating(movieID: movieID, sessionID: sessionID)
    }

    public func setRating(_ value: Double?, movieID: Int) async throws {
        guard let sessionID = await sessionProvider.sessionID() else {
            throw MovieRatingError.notAuthenticated
        }
        if let value {
            try await remote.rate(movieID: movieID, value: value, sessionID: sessionID)
        } else {
            try await remote.deleteRating(movieID: movieID, sessionID: sessionID)
        }
    }
}
