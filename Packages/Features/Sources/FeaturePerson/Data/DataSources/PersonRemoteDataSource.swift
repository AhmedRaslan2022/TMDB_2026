//
//  PersonRemoteDataSource.swift
//  TMDB
//
//  Created by Ahmed Raslan on 21/07/2026.
//

import Networking

/// Raw TMDB person calls, returning the DTO. Internal: only the repository
/// consumes it; the protocol exists so repository tests can mock the wire.
protocol PersonRemoteDataSource: Sendable {
    func fetchDetails(personID: Int) async throws -> PersonDetailsDTO
}

struct PersonRemoteDataSourceImpl: PersonRemoteDataSource {
    let apiClient: any APIClient

    func fetchDetails(personID: Int) async throws -> PersonDetailsDTO {
        try await apiClient.send(PersonEndpoint(personID: personID))
    }
}
