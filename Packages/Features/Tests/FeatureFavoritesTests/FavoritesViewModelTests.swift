//
//  FavoritesViewModelTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

import CoreModels
import Foundation
import Testing
@testable import FeatureFavorites

@MainActor
@Suite("FavoritesViewModel")
struct FavoritesViewModelTests {
    private enum MockError: Error { case load }

    private let repository = FavoritesRepositoryMock()
    private let viewModel: FavoritesViewModel

    init() throws {
        viewModel = try FavoritesViewModel(
            repository: repository,
            imageBaseURL: #require(URL(string: "https://img.invalid/t/p"))
        )
    }

    @Test("load shows local favorites and reconciles once")
    func loadShowsAndSyncs() async {
        repository.seed([1, 2, 3])

        await viewModel.load()

        #expect(viewModel.state == .loaded(repository.movies))
        #expect(repository.syncCount == 1, "reconciles once on first load")

        await viewModel.load()
        #expect(repository.syncCount == 1, "second appearance doesn't re-sync")
    }

    @Test("no favorites lands in the empty state")
    func emptyState() async {
        await viewModel.load()

        #expect(viewModel.state == .empty)
    }

    @Test("a load failure lands in error")
    func errorState() async {
        repository.favoritesError = MockError.load

        await viewModel.load()

        guard case .error = viewModel.state else {
            Issue.record("expected .error, got \(viewModel.state)")
            return
        }
    }

    @Test("remove persists the un-favorite and drops it from the list")
    func remove() async {
        repository.seed([1, 2])
        await viewModel.load()

        await viewModel.remove(favoriteTestMovie(1))

        #expect(repository.setCalls.map(\.movieID) == [1])
        #expect(repository.setCalls.map(\.isFavorite) == [false])
        #expect(viewModel.state == .loaded([favoriteTestMovie(2)]))
    }

    @Test("removing the last favorite shows the empty state")
    func removeLast() async {
        repository.seed([1])
        await viewModel.load()

        await viewModel.remove(favoriteTestMovie(1))

        #expect(viewModel.state == .empty)
    }

    @Test("pull-to-refresh reconciles and re-reads")
    func refresh() async {
        await viewModel.load()
        let syncsAfterLoad = repository.syncCount
        repository.seed([9])

        await viewModel.refresh()

        #expect(repository.syncCount == syncsAfterLoad + 1)
        #expect(viewModel.state == .loaded([favoriteTestMovie(9)]))
    }
}
