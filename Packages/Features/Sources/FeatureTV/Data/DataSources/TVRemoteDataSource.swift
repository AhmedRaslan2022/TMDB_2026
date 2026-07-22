//
//  TVRemoteDataSource.swift
//  TMDB
//
//  Created by Ahmed Raslan on 21/07/2026.
//

import Networking

/// Raw TMDB TV calls, returning DTOs. Internal: only the repositories consume
/// them; the protocols exist so repository tests can mock the wire.
protocol TVListRemoteDataSource: Sendable {
    func fetchPage(list: TVList, page: Int) async throws -> TVPageDTO
}

protocol TVDetailsRemoteDataSource: Sendable {
    func fetchDetails(showID: Int) async throws -> TVShowDetailsDTO
}

struct TVListRemoteDataSourceImpl: TVListRemoteDataSource {
    let apiClient: any APIClient

    func fetchPage(list: TVList, page: Int) async throws -> TVPageDTO {
        try await apiClient.send(TVListEndpoint(list: list, page: page))
    }
}

struct TVDetailsRemoteDataSourceImpl: TVDetailsRemoteDataSource {
    let apiClient: any APIClient

    func fetchDetails(showID: Int) async throws -> TVShowDetailsDTO {
        try await apiClient.send(TVDetailsEndpoint(showID: showID))
    }
}
