//
//  MovieDetailsRemoteDataSource.swift
//  TMDB
//
//  Created by Ahmed Raslan on 19/07/2026.
//

import Networking

/// Raw TMDB details call, returning the DTO. Internal: only the repository
/// consumes it; the protocol exists so repository tests can mock the wire.
protocol MovieDetailsRemoteDataSource: Sendable {
    func fetchDetails(movieID: Int) async throws -> MovieDetailsDTO
}

struct MovieDetailsRemoteDataSourceImpl: MovieDetailsRemoteDataSource {
    let apiClient: any APIClient

    func fetchDetails(movieID: Int) async throws -> MovieDetailsDTO {
        try await apiClient.send(MovieDetailsEndpoint(movieID: movieID))
    }
}
