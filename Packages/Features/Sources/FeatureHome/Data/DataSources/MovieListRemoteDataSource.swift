//
//  MovieListRemoteDataSource.swift
//  TMDB
//
//  Created by Ahmed Raslan on 18/07/2026.
//

import Networking

/// Raw TMDB movie-list calls, returning DTOs. Internal: only the repository
/// consumes it; the protocol exists so repository tests can mock the wire.
protocol MovieListRemoteDataSource: Sendable {
    func fetchPage(list: MovieList, page: Int) async throws -> MoviePageDTO
}

struct MovieListRemoteDataSourceImpl: MovieListRemoteDataSource {
    let apiClient: any APIClient

    func fetchPage(list: MovieList, page: Int) async throws -> MoviePageDTO {
        try await apiClient.send(MovieListEndpoint(list: list, page: page))
    }
}
