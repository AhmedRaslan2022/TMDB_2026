//
//  DiscoverRemoteDataSource.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

import Networking

/// Raw TMDB Discover + genre calls, returning DTOs. Internal: only the
/// repository consumes it; the protocol exists so repository tests can mock it.
protocol DiscoverRemoteDataSource: Sendable {
    func genres() async throws -> GenreListDTO
    func discover(filters: DiscoverFilters, page: Int) async throws -> SearchPageDTO
}

struct DiscoverRemoteDataSourceImpl: DiscoverRemoteDataSource {
    let apiClient: any APIClient

    func genres() async throws -> GenreListDTO {
        try await apiClient.send(GenresEndpoint())
    }

    func discover(filters: DiscoverFilters, page: Int) async throws -> SearchPageDTO {
        try await apiClient.send(DiscoverEndpoint(filters: filters, page: page))
    }
}
