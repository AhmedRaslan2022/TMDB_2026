//
//  FetchTVListUseCaseTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 22/07/2026.
//

import CoreModels
import Testing
@testable import FeatureTV

@MainActor
@Suite("FetchTVListUseCase")
struct FetchTVListUseCaseTests {
    @MainActor
    private final class RepositoryMock: TVListRepository {
        var result: Result<MoviePage, Error> = .success(MoviePage(page: 1, movies: [], totalPages: 1))
        private(set) var calls: [(list: TVList, page: Int)] = []

        func shows(in list: TVList, page: Int) async throws -> MoviePage {
            calls.append((list, page))
            return try result.get()
        }
    }

    private enum UseCaseError: Error { case boom }

    private let repository = RepositoryMock()
    private var useCase: FetchTVListUseCaseImpl {
        FetchTVListUseCaseImpl(repository: repository)
    }

    @Test("forwards the exact list and page to the repository")
    func forwardsListAndPage() async throws {
        _ = try await useCase.execute(list: .topRated, page: 3)

        #expect(repository.calls.count == 1)
        #expect(repository.calls.first?.list == .topRated)
        #expect(repository.calls.first?.page == 3)
    }

    @Test("returns the repository's page unchanged")
    func returnsPage() async throws {
        let page = MoviePage(page: 2, movies: [Movie(id: 9, title: "S", overview: "")], totalPages: 4)
        repository.result = .success(page)

        let result = try await useCase.execute(list: .onTheAir, page: 2)

        #expect(result == page)
    }

    @Test("propagates repository errors")
    func propagatesError() async {
        repository.result = .failure(UseCaseError.boom)

        await #expect(throws: UseCaseError.self) {
            _ = try await useCase.execute(list: .popular, page: 1)
        }
    }
}
