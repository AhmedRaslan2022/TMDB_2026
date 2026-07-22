//
//  MovieSearchRepositoryImpl.swift
//  TMDB
//
//  Created by Ahmed Raslan on 19/07/2026.
//

import CoreModels
import Networking

/// `MovieSearchRepository` over the TMDB API. Maps DTOs to Domain at the
/// boundary; DTOs never leave this layer.
public struct MovieSearchRepositoryImpl: MovieSearchRepository {
    private let dataSource: any SearchRemoteDataSource

    /// Composition-root entry point: wires the internal data source.
    public init(apiClient: any APIClient) {
        self.init(dataSource: SearchRemoteDataSourceImpl(apiClient: apiClient))
    }

    init(dataSource: any SearchRemoteDataSource) {
        self.dataSource = dataSource
    }

    public func search(query: String, page: Int) async throws -> MoviePage {
        try await dataSource.search(query: query, page: page).toDomain()
    }
}
