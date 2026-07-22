//
//  DiscoverRepositoryImpl.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

import CoreModels
import Networking

/// `DiscoverRepository` over the Discover + genre endpoints. Reuses the
/// feature's `SearchPageDTO`/mapper since Discover returns the same movie-page
/// wire shape as search.
public struct DiscoverRepositoryImpl: DiscoverRepository {
    private let remote: any DiscoverRemoteDataSource

    /// Composition-root entry point.
    public init(apiClient: any APIClient) {
        self.init(remote: DiscoverRemoteDataSourceImpl(apiClient: apiClient))
    }

    init(remote: any DiscoverRemoteDataSource) {
        self.remote = remote
    }

    public func genres() async throws -> [MovieGenre] {
        try await remote.genres().toDomain()
    }

    public func discover(filters: DiscoverFilters, page: Int) async throws -> MoviePage {
        try await remote.discover(filters: filters, page: page).toDomain()
    }
}
