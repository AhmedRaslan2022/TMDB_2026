//
//  FetchMovieListUseCase.swift
//  TMDB
//
//  Created by Ahmed Raslan on 18/07/2026.
//

import CoreModels

/// Fetches one page of a movie list. Parameterized over `MovieList` so the
/// home screen's parallel section fetch drives a single use case.
public protocol FetchMovieListUseCase: Sendable {
    func execute(list: MovieList, page: Int) async throws -> MoviePage
}

public struct FetchMovieListUseCaseImpl: FetchMovieListUseCase {
    private let repository: any MovieListRepository

    public init(repository: any MovieListRepository) {
        self.repository = repository
    }

    public func execute(list: MovieList, page: Int) async throws -> MoviePage {
        try await repository.movies(in: list, page: page)
    }
}
