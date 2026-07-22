//
//  SearchMoviesUseCaseTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 19/07/2026.
//

import CoreModels
import Foundation
import Testing
@testable import FeatureSearch

@MainActor
@Suite("SearchMoviesUseCase")
struct SearchMoviesUseCaseTests {
    @MainActor
    private final class SearchRepositoryMock: MovieSearchRepository {
        var result = MoviePage(page: 1, movies: [], totalPages: 1)
        private(set) var queries: [(query: String, page: Int)] = []

        func search(query: String, page: Int) async throws -> MoviePage {
            queries.append((query, page))
            return result
        }
    }

    private let repository = SearchRepositoryMock()
    private var useCase: SearchMoviesUseCaseImpl {
        SearchMoviesUseCaseImpl(repository: repository)
    }

    @Test("forwards the trimmed query and page")
    func forwardsTrimmed() async throws {
        _ = try await useCase.execute(query: "  dune  ", page: 2)

        #expect(repository.queries.count == 1)
        #expect(repository.queries.first?.query == "dune")
        #expect(repository.queries.first?.page == 2)
    }

    @Test("blank queries short-circuit to an empty page without touching the API", arguments: ["", "   ", "\n\t "])
    func blankQueryShortCircuits(query: String) async throws {
        let page = try await useCase.execute(query: query, page: 1)

        #expect(page.movies.isEmpty)
        #expect(!page.hasMorePages)
        #expect(repository.queries.isEmpty)
    }
}
