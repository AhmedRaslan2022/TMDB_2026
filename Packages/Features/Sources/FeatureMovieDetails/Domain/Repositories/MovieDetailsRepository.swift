//
//  MovieDetailsRepository.swift
//  TMDB
//
//  Created by Ahmed Raslan on 19/07/2026.
//

/// Access to a movie's full detail bundle. Implemented in the Data layer;
/// consumers depend on this protocol so tests can mock it.
public protocol MovieDetailsRepository: Sendable {
    func detailsBundle(for movieID: Int) async throws -> MovieDetailsBundle
}
