//
//  SearchRemoteDataSource.swift
//  TMDB
//
//  Created by Ahmed Raslan on 19/07/2026.
//

import Networking

/// Raw TMDB search calls, returning DTOs. Internal: only the repository
/// consumes it; the protocol exists so repository tests can mock the wire.
protocol SearchRemoteDataSource: Sendable {
    func search(query: String, page: Int) async throws -> SearchPageDTO
}

struct SearchRemoteDataSourceImpl: SearchRemoteDataSource {
    let apiClient: any APIClient

    func search(query: String, page: Int) async throws -> SearchPageDTO {
        try await apiClient.send(SearchEndpoint(query: query, page: page))
    }
}
