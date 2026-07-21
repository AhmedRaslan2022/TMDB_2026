//
//  FetchTVDetailsUseCase.swift
//  TMDB
//
//  Created by Ahmed Raslan on 21/07/2026.
//

/// Fetches a TV show's detail bundle.
public protocol FetchTVDetailsUseCase: Sendable {
    func execute(showID: Int) async throws -> TVShowDetailsBundle
}

public struct FetchTVDetailsUseCaseImpl: FetchTVDetailsUseCase {
    private let repository: any TVDetailsRepository

    public init(repository: any TVDetailsRepository) {
        self.repository = repository
    }

    public func execute(showID: Int) async throws -> TVShowDetailsBundle {
        try await repository.detailsBundle(for: showID)
    }
}
