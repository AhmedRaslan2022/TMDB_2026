//
//  DiscoverMoviesUseCaseTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 22/07/2026.
//

import CoreModels
import Testing
@testable import FeatureSearch

@MainActor
@Suite("DiscoverMoviesUseCase")
struct DiscoverMoviesUseCaseTests {
    @MainActor
    private final class RepositoryMock: DiscoverRepository {
        var genresResult: Result<[MovieGenre], Error> = .success([])
        var discoverResult: Result<MoviePage, Error> = .success(MoviePage(page: 1, movies: [], totalPages: 1))
        private(set) var discoverCalls: [(filters: DiscoverFilters, page: Int)] = []
        private(set) var genresCalled = 0

        func genres() async throws -> [MovieGenre] {
            genresCalled += 1
            return try genresResult.get()
        }

        func discover(filters: DiscoverFilters, page: Int) async throws -> MoviePage {
            discoverCalls.append((filters, page))
            return try discoverResult.get()
        }
    }

    private enum UseCaseError: Error { case boom }

    private let repository = RepositoryMock()
    private var useCase: DiscoverMoviesUseCaseImpl {
        DiscoverMoviesUseCaseImpl(repository: repository)
    }

    @Test("genres() delegates to the repository and returns its catalog")
    func genresDelegates() async throws {
        repository.genresResult = .success([MovieGenre(id: 28, name: "Action")])

        let genres = try await useCase.genres()

        #expect(repository.genresCalled == 1)
        #expect(genres == [MovieGenre(id: 28, name: "Action")])
    }

    @Test("execute forwards the exact filters and page")
    func executeForwards() async throws {
        let filters = DiscoverFilters(year: 1999, minimumRating: 8, sort: .rating)

        _ = try await useCase.execute(filters: filters, page: 4)

        #expect(repository.discoverCalls.count == 1)
        #expect(repository.discoverCalls.first?.filters == filters)
        #expect(repository.discoverCalls.first?.page == 4)
    }

    @Test("execute returns the repository's page unchanged")
    func executeReturnsPage() async throws {
        let page = MoviePage(page: 2, movies: [Movie(id: 1, title: "M", overview: "")], totalPages: 3)
        repository.discoverResult = .success(page)

        let result = try await useCase.execute(filters: DiscoverFilters(), page: 2)

        #expect(result == page)
    }

    @Test("propagates repository errors from both entry points")
    func propagatesErrors() async {
        repository.genresResult = .failure(UseCaseError.boom)
        repository.discoverResult = .failure(UseCaseError.boom)

        await #expect(throws: UseCaseError.self) { _ = try await useCase.genres() }
        await #expect(throws: UseCaseError.self) {
            _ = try await useCase.execute(filters: DiscoverFilters(), page: 1)
        }
    }
}
