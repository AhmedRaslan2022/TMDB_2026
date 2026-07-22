//
//  FetchTVDetailsUseCaseTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 22/07/2026.
//

import CoreModels
import Testing
@testable import FeatureTV

@MainActor
@Suite("FetchTVDetailsUseCase")
struct FetchTVDetailsUseCaseTests {
    @MainActor
    private final class RepositoryMock: TVDetailsRepository {
        var result: Result<TVShowDetailsBundle, Error> = .success(
            TVShowDetailsBundle(details: TVShowDetails(id: 0, name: "", overview: ""))
        )
        private(set) var requestedIDs: [Int] = []

        func detailsBundle(for showID: Int) async throws -> TVShowDetailsBundle {
            requestedIDs.append(showID)
            return try result.get()
        }
    }

    private enum UseCaseError: Error { case boom }

    private let repository = RepositoryMock()
    private var useCase: FetchTVDetailsUseCaseImpl {
        FetchTVDetailsUseCaseImpl(repository: repository)
    }

    @Test("forwards the exact show id to the repository")
    func forwardsID() async throws {
        _ = try await useCase.execute(showID: 1396)

        #expect(repository.requestedIDs == [1396])
    }

    @Test("returns the repository's bundle unchanged")
    func returnsBundle() async throws {
        let bundle = TVShowDetailsBundle(
            details: TVShowDetails(id: 1396, name: "Breaking Bad", overview: "…"),
            similar: [MediaItem(id: 1400, mediaType: .tv, title: "The Sopranos", overview: "")]
        )
        repository.result = .success(bundle)

        let result = try await useCase.execute(showID: 1396)

        #expect(result == bundle)
    }

    @Test("propagates repository errors")
    func propagatesError() async {
        repository.result = .failure(UseCaseError.boom)

        await #expect(throws: UseCaseError.self) {
            _ = try await useCase.execute(showID: 1)
        }
    }
}
