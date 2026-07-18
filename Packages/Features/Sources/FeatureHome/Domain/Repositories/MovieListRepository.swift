//
//  MovieListRepository.swift
//  TMDB
//
//  Created by Ahmed Raslan on 18/07/2026.
//

import CoreModels

/// Access to TMDB's movie lists. Implemented in the Data layer; consumers
/// depend on this protocol so tests can mock it.
public protocol MovieListRepository: Sendable {
    /// One page of `list`, 1-based like the TMDB API.
    func movies(in list: MovieList, page: Int) async throws -> MoviePage
}
