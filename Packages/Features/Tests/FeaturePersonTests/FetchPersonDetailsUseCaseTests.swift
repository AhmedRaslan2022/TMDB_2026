//
//  FetchPersonDetailsUseCaseTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 22/07/2026.
//

import CoreModels
import Testing
@testable import FeaturePerson

@MainActor
@Suite("FetchPersonDetailsUseCase")
struct FetchPersonDetailsUseCaseTests {
    @MainActor
    private final class RepositoryMock: PersonRepository {
        var result: Result<PersonDetailsBundle, Error> = .success(
            PersonDetailsBundle(person: Person(id: 0, name: "", biography: ""), filmography: [])
        )
        private(set) var requestedIDs: [Int] = []

        func detailsBundle(for personID: Int) async throws -> PersonDetailsBundle {
            requestedIDs.append(personID)
            return try result.get()
        }
    }

    private enum UseCaseError: Error { case boom }

    private let repository = RepositoryMock()
    private var useCase: FetchPersonDetailsUseCaseImpl {
        FetchPersonDetailsUseCaseImpl(repository: repository)
    }

    @Test("forwards the exact person id to the repository")
    func forwardsID() async throws {
        _ = try await useCase.execute(personID: 287)

        #expect(repository.requestedIDs == [287])
    }

    @Test("returns the repository's bundle unchanged")
    func returnsBundle() async throws {
        let bundle = PersonDetailsBundle(
            person: Person(id: 287, name: "Brad Pitt", biography: "…"),
            filmography: [PersonCredit(media: MediaItem(id: 550, title: "Fight Club", overview: ""))]
        )
        repository.result = .success(bundle)

        let result = try await useCase.execute(personID: 287)

        #expect(result.person.id == 287)
        #expect(result.filmography.count == 1)
        #expect(result.filmography.first?.media.id == 550)
    }

    @Test("propagates repository errors")
    func propagatesError() async {
        repository.result = .failure(UseCaseError.boom)

        await #expect(throws: UseCaseError.self) {
            _ = try await useCase.execute(personID: 1)
        }
    }
}
