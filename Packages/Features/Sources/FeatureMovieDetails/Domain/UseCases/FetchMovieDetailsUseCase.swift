//
//  FetchMovieDetailsUseCase.swift
//  TMDB
//
//  Created by Ahmed Raslan on 19/07/2026.
//

/// Fetches a movie's full detail bundle (details, cast, videos, similar,
/// recommendations) in one shot.
public protocol FetchMovieDetailsUseCase: Sendable {
    func execute(movieID: Int) async throws -> MovieDetailsBundle
}

public struct FetchMovieDetailsUseCaseImpl: FetchMovieDetailsUseCase {
    private let repository: any MovieDetailsRepository

    public init(repository: any MovieDetailsRepository) {
        self.repository = repository
    }

    public func execute(movieID: Int) async throws -> MovieDetailsBundle {
        try await repository.detailsBundle(for: movieID)
    }
}
