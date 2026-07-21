//
//  FetchMovieDetailsUseCaseTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 22/07/2026.
//

import Testing
@testable import FeatureMovieDetails

@MainActor
@Suite("FetchMovieDetailsUseCase")
struct FetchMovieDetailsUseCaseTests {
    @MainActor
    private final class RepositoryMock: MovieDetailsRepository {
        var result: Result<MovieDetailsBundle, Error> = .success(
            MovieDetailsBundle(details: MovieDetails(id: 0, title: "", overview: ""))
        )
        private(set) var requestedIDs: [Int] = []

        func detailsBundle(for movieID: Int) async throws -> MovieDetailsBundle {
            requestedIDs.append(movieID)
            return try result.get()
        }
    }

    private enum UseCaseError: Error { case boom }

    private let repository = RepositoryMock()
    private var useCase: FetchMovieDetailsUseCaseImpl {
        FetchMovieDetailsUseCaseImpl(repository: repository)
    }

    @Test("forwards the exact movie id to the repository")
    func forwardsID() async throws {
        _ = try await useCase.execute(movieID: 550)

        #expect(repository.requestedIDs == [550])
    }

    @Test("returns the repository's bundle unchanged")
    func returnsBundle() async throws {
        let bundle = MovieDetailsBundle(details: MovieDetails(id: 550, title: "Fight Club", overview: "…"))
        repository.result = .success(bundle)

        let result = try await useCase.execute(movieID: 550)

        #expect(result == bundle)
    }

    @Test("propagates repository errors")
    func propagatesError() async {
        repository.result = .failure(UseCaseError.boom)

        await #expect(throws: UseCaseError.self) {
            _ = try await useCase.execute(movieID: 1)
        }
    }
}
