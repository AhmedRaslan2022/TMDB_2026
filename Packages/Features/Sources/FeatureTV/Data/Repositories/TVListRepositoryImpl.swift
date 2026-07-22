//
//  TVListRepositoryImpl.swift
//  TMDB
//
//  Created by Ahmed Raslan on 21/07/2026.
//

import CoreModels
import Networking

/// `TVListRepository` over the TMDB API. Maps DTOs to the shared `MediaItem`
/// at the boundary; DTOs never leave this layer. Mirrors `MovieListRepositoryImpl`.
public struct TVListRepositoryImpl: TVListRepository {
    private let dataSource: any TVListRemoteDataSource

    /// Composition-root entry point.
    public init(apiClient: any APIClient) {
        self.init(dataSource: TVListRemoteDataSourceImpl(apiClient: apiClient))
    }

    init(dataSource: any TVListRemoteDataSource) {
        self.dataSource = dataSource
    }

    public func shows(in list: TVList, page: Int) async throws -> MoviePage {
        try await dataSource.fetchPage(list: list, page: page).toDomain()
    }
}
