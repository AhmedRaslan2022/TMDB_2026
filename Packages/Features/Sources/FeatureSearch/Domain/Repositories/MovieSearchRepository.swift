//
//  MovieSearchRepository.swift
//  TMDB
//
//  Created by Ahmed Raslan on 19/07/2026.
//

import CoreModels

/// Access to TMDB movie search. Implemented in the Data layer; consumers
/// depend on this protocol so tests can mock it. Discover (Sprint 5) gets
/// its own repository — filtering and text search have different shapes.
public protocol MovieSearchRepository: Sendable {
    /// One page of results for `query`, 1-based like the TMDB API.
    /// Callers pass a non-blank query — trimming and blank short-circuiting
    /// are the use case's job; TMDB rejects an empty `query` parameter.
    func search(query: String, page: Int) async throws -> MoviePage
}
