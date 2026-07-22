//
//  MovieDetailsRepositoryImpl.swift
//  TMDB
//
//  Created by Ahmed Raslan on 19/07/2026.
//

import Networking

/// `MovieDetailsRepository` over the TMDB API. Maps DTOs to Domain at the
/// boundary; DTOs never leave this layer.
public struct MovieDetailsRepositoryImpl: MovieDetailsRepository {
    private let dataSource: any MovieDetailsRemoteDataSource

    /// Composition-root entry point: wires the internal data source.
    public init(apiClient: any APIClient) {
        self.init(dataSource: MovieDetailsRemoteDataSourceImpl(apiClient: apiClient))
    }

    init(dataSource: any MovieDetailsRemoteDataSource) {
        self.dataSource = dataSource
    }

    public func detailsBundle(for movieID: Int) async throws -> MovieDetailsBundle {
        try await dataSource.fetchDetails(movieID: movieID).toDomain()
    }
}
