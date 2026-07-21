//
//  PersonRepositoryImpl.swift
//  TMDB
//
//  Created by Ahmed Raslan on 21/07/2026.
//

import Networking

/// `PersonRepository` over the TMDB API. Maps the appended `/person/{id}`
/// payload into a `PersonDetailsBundle`; DTOs never leave this layer.
public struct PersonRepositoryImpl: PersonRepository {
    private let dataSource: any PersonRemoteDataSource

    /// Composition-root entry point.
    public init(apiClient: any APIClient) {
        self.init(dataSource: PersonRemoteDataSourceImpl(apiClient: apiClient))
    }

    init(dataSource: any PersonRemoteDataSource) {
        self.dataSource = dataSource
    }

    public func detailsBundle(for personID: Int) async throws -> PersonDetailsBundle {
        try await dataSource.fetchDetails(personID: personID).toDomainBundle()
    }
}
