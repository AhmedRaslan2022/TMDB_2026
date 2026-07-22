//
//  DiscoverViewModelTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

import CoreModels
import Foundation
import Testing
@testable import FeatureSearch

@MainActor
@Suite("DiscoverViewModel")
struct DiscoverViewModelTests {
    private let useCase = DiscoverUseCaseMock()
    private let viewModel: DiscoverViewModel

    init() throws {
        viewModel = try DiscoverViewModel(
            discoverMovies: useCase,
            imageBaseURL: #require(URL(string: "https://img.invalid/t/p"))
        )
    }

    private func movies() throws -> [Movie] {
        guard case let .loaded(content) = viewModel.state else {
            throw MockError.stubbed
        }
        return content.movies
    }

    @Test("load fetches the genre catalog and the first page")
    func loadSuccess() async throws {
        useCase.stubbedGenres = [MovieGenre(id: 28, name: "Action")]
        useCase.stubPage(1, ids: 1 ... 3)

        await viewModel.load()

        #expect(viewModel.genres.map(\.id) == [28])
        #expect(try movies().map(\.id) == [1, 2, 3])
        #expect(useCase.requestedPages == [1])
    }

    @Test("load is idempotent once results exist")
    func loadIdempotent() async {
        useCase.stubPage(1, ids: 1 ... 3)
        await viewModel.load()

        await viewModel.load()

        #expect(useCase.requestedPages == [1])
    }

    @Test("a failed genre load still browses (empty genre picker)")
    func genreFailureTolerated() async throws {
        useCase.genresError = MockError.stubbed
        useCase.stubPage(1, ids: 1 ... 2)

        await viewModel.load()

        #expect(viewModel.genres.isEmpty)
        #expect(try movies().map(\.id) == [1, 2])
    }

    @Test("empty results land in .empty")
    func emptyResults() async {
        await viewModel.load()

        #expect(viewModel.state == .empty)
    }

    @Test("a discover failure lands in .error")
    func discoverError() async {
        useCase.discoverError = MockError.stubbed

        await viewModel.load()

        guard case .error = viewModel.state else {
            Issue.record("expected .error, got \(viewModel.state)")
            return
        }
    }

    @Test("toggling a genre reloads with the new filter applied")
    func toggleGenreReloads() async {
        useCase.stubPage(1, ids: 1 ... 3)
        await viewModel.load()

        await viewModel.toggleGenre(28)

        #expect(viewModel.filters.genreIDs == [28])
        #expect(useCase.requestedFilters.last?.genreIDs == [28])
        #expect(useCase.requestedPages == [1, 1], "a filter change reloads from page 1")
    }

    @Test("setting sort, year, and rating each reload with the value")
    func filterSettersReload() async {
        useCase.stubPage(1, ids: 1 ... 3)
        await viewModel.load()

        await viewModel.setSort(.rating)
        await viewModel.setYear(1999)
        await viewModel.setMinimumRating(8)

        #expect(viewModel.filters.sort == .rating)
        #expect(viewModel.filters.year == 1999)
        #expect(viewModel.filters.minimumRating == 8)
        #expect(useCase.requestedFilters.last == DiscoverFilters(year: 1999, minimumRating: 8, sort: .rating))
    }

    @Test("an unchanged filter set does not reload")
    func noReloadOnUnchanged() async {
        useCase.stubPage(1, ids: 1 ... 3)
        await viewModel.load()

        await viewModel.setSort(.popularity) // already the default

        #expect(useCase.requestedPages == [1], "no redundant reload for an unchanged value")
    }

    @Test("clearing filters resets to defaults and reloads")
    func clearResets() async {
        useCase.stubPage(1, ids: 1 ... 3)
        await viewModel.load()
        await viewModel.toggleGenre(28)

        await viewModel.clearFilters()

        #expect(viewModel.filters.isActive == false)
        #expect(useCase.requestedFilters.last == DiscoverFilters())
    }

    @Test("pagination appends the next page and dedupes overlap")
    func paginationAppends() async throws {
        useCase.stubPage(1, ids: 1 ... 5, totalPages: 2)
        useCase.stubPage(2, ids: 4 ... 8, totalPages: 2)
        await viewModel.load()

        let last = try #require(try movies().last)
        await viewModel.loadMoreIfNeeded(after: last)

        #expect(try movies().map(\.id) == [1, 2, 3, 4, 5, 6, 7, 8])
        #expect(useCase.requestedPages == [1, 2])
    }
}
