//
//  TVDetailsRepositoryImpl.swift
//  TMDB
//
//  Created by Ahmed Raslan on 21/07/2026.
//

import Networking

/// `TVDetailsRepository` over the TMDB API. Maps the appended `/tv/{id}`
/// payload into a `TVShowDetailsBundle`; DTOs never leave this layer.
public struct TVDetailsRepositoryImpl: TVDetailsRepository {
    private let dataSource: any TVDetailsRemoteDataSource

    /// Composition-root entry point.
    public init(apiClient: any APIClient) {
        self.init(dataSource: TVDetailsRemoteDataSourceImpl(apiClient: apiClient))
    }

    init(dataSource: any TVDetailsRemoteDataSource) {
        self.dataSource = dataSource
    }

    public func detailsBundle(for showID: Int) async throws -> TVShowDetailsBundle {
        try await dataSource.fetchDetails(showID: showID).toDomainBundle()
    }
}
