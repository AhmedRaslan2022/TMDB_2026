//
//  PersonRepository.swift
//  TMDB
//
//  Created by Ahmed Raslan on 21/07/2026.
//

/// Access to a person's detail bundle. Implemented in the Data layer.
public protocol PersonRepository: Sendable {
    func detailsBundle(for personID: Int) async throws -> PersonDetailsBundle
}
