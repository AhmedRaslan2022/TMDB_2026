//
//  SearchMoviesUseCase.swift
//  TMDB
//
//  Created by Ahmed Raslan on 19/07/2026.
//

import CoreModels
import Foundation

/// Searches TMDB for movies matching a free-text query.
///
/// Blank or whitespace-only queries return an empty first page WITHOUT a
/// network call (`page` is ignored in that case) — indistinguishable from a
/// genuine zero-hit result, so presentation must gate "idle vs no-results"
/// on the query text, not the returned page.
public protocol SearchMoviesUseCase: Sendable {
    func execute(query: String, page: Int) async throws -> MoviePage
}

public struct SearchMoviesUseCaseImpl: SearchMoviesUseCase {
    private let repository: any MovieSearchRepository

    public init(repository: any MovieSearchRepository) {
        self.repository = repository
    }

    public func execute(query: String, page: Int) async throws -> MoviePage {
        // A blank query has a defined answer — no results — and the API
        // shouldn't be asked about it.
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return MoviePage(page: 1, movies: [], totalPages: 1)
        }
        return try await repository.search(query: trimmed, page: page)
    }
}
