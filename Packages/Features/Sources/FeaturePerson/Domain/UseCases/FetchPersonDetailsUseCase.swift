//
//  FetchPersonDetailsUseCase.swift
//  TMDB
//
//  Created by Ahmed Raslan on 21/07/2026.
//

/// Fetches a person's detail bundle (bio, filmography, images).
public protocol FetchPersonDetailsUseCase: Sendable {
    func execute(personID: Int) async throws -> PersonDetailsBundle
}

public struct FetchPersonDetailsUseCaseImpl: FetchPersonDetailsUseCase {
    private let repository: any PersonRepository

    public init(repository: any PersonRepository) {
        self.repository = repository
    }

    public func execute(personID: Int) async throws -> PersonDetailsBundle {
        try await repository.detailsBundle(for: personID)
    }
}
