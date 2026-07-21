//
//  FetchTVListUseCase.swift
//  TMDB
//
//  Created by Ahmed Raslan on 21/07/2026.
//

import CoreModels

/// Fetches one page of a TV list. Mirrors `FetchMovieListUseCase` exactly —
/// same shape, same `MoviePage` return — which is what 6.6's reuse-safety
/// tests assert across both media types.
public protocol FetchTVListUseCase: Sendable {
    func execute(list: TVList, page: Int) async throws -> MoviePage
}

public struct FetchTVListUseCaseImpl: FetchTVListUseCase {
    private let repository: any TVListRepository

    public init(repository: any TVListRepository) {
        self.repository = repository
    }

    public func execute(list: TVList, page: Int) async throws -> MoviePage {
        try await repository.shows(in: list, page: page)
    }
}
