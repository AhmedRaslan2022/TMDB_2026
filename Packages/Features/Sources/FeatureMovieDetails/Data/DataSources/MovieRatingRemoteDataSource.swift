//
//  MovieRatingRemoteDataSource.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

import Networking

/// Raw TMDB rating calls. Internal: only the repository consumes it; the
/// protocol exists so repository tests can mock the wire.
protocol MovieRatingRemoteDataSource: Sendable {
    /// The user's current rating for a movie, or `nil` when unrated.
    func rating(movieID: Int, sessionID: String) async throws -> Double?
    func rate(movieID: Int, value: Double, sessionID: String) async throws
    func deleteRating(movieID: Int, sessionID: String) async throws
}

struct MovieRatingRemoteDataSourceImpl: MovieRatingRemoteDataSource {
    let apiClient: any APIClient

    func rating(movieID: Int, sessionID: String) async throws -> Double? {
        let dto: AccountStatesDTO = try await apiClient.send(
            MovieRatingEndpoint.accountStates(movieID: movieID, sessionID: sessionID)
        )
        return dto.ratingValue
    }

    func rate(movieID: Int, value: Double, sessionID: String) async throws {
        try await apiClient.sendRaw(
            MovieRatingEndpoint.rate(movieID: movieID, value: value, sessionID: sessionID)
        )
    }

    func deleteRating(movieID: Int, sessionID: String) async throws {
        try await apiClient.sendRaw(
            MovieRatingEndpoint.delete(movieID: movieID, sessionID: sessionID)
        )
    }
}
