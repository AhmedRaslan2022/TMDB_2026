//
//  TVDetailsRepository.swift
//  TMDB
//
//  Created by Ahmed Raslan on 21/07/2026.
//

/// Access to a TV show's detail bundle. Implemented in the Data layer.
public protocol TVDetailsRepository: Sendable {
    func detailsBundle(for showID: Int) async throws -> TVShowDetailsBundle
}
