//
//  DiscoverMoviesUseCase.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

import CoreModels

/// Browses movies by advanced filters (genre, year, rating, sort), plus the
/// genre catalog the filter UI needs.
public protocol DiscoverMoviesUseCase: Sendable {
    func genres() async throws -> [MovieGenre]
    func execute(filters: DiscoverFilters, page: Int) async throws -> MoviePage
}

public struct DiscoverMoviesUseCaseImpl: DiscoverMoviesUseCase {
    private let repository: any DiscoverRepository

    public init(repository: any DiscoverRepository) {
        self.repository = repository
    }

    public func genres() async throws -> [MovieGenre] {
        try await repository.genres()
    }

    public func execute(filters: DiscoverFilters, page: Int) async throws -> MoviePage {
        try await repository.discover(filters: filters, page: page)
    }
}
