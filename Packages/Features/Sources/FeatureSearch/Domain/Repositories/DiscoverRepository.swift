//
//  DiscoverRepository.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

import CoreModels

/// Access to TMDB's Discover endpoint and the genre catalog that powers the
/// filter UI. Implemented in the Data layer; consumers depend on the protocol.
/// Separate from `MovieSearchRepository` because filtering and free-text search
/// have different shapes (recorded in 4.1).
public protocol DiscoverRepository: Sendable {
    /// The movie genre catalog, for building the filter picker.
    func genres() async throws -> [MovieGenre]
    /// One page of results matching `filters`, 1-based like the TMDB API.
    func discover(filters: DiscoverFilters, page: Int) async throws -> MoviePage
}
