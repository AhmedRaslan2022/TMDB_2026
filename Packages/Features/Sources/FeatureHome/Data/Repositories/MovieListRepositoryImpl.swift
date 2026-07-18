//
//  MovieListRepositoryImpl.swift
//  TMDB
//
//  Created by Ahmed Raslan on 18/07/2026.
//

import CoreModels
import Networking

/// `MovieListRepository` over the TMDB API. Maps DTOs to Domain entities at
/// the boundary; DTOs never leave this layer. (Offline caching of lists is a
/// later sprint's concern — this stays network-only for now.)
public struct MovieListRepositoryImpl: MovieListRepository {
    private let dataSource: any MovieListRemoteDataSource

    /// Composition-root entry point: wires the internal data source.
    public init(apiClient: any APIClient) {
        self.init(dataSource: MovieListRemoteDataSourceImpl(apiClient: apiClient))
    }

    init(dataSource: any MovieListRemoteDataSource) {
        self.dataSource = dataSource
    }

    public func movies(in list: MovieList, page: Int) async throws -> MoviePage {
        try await dataSource.fetchPage(list: list, page: page).toDomain()
    }
}
