//
//  TVDetailsViewModelTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 21/07/2026.
//

import CoreModels
import Foundation
import Testing
@testable import FeatureTV

@MainActor
@Suite("TVDetailsViewModel")
struct TVDetailsViewModelTests {
    private enum MockError: Error { case stubbed }

    @MainActor
    private final class FetchMock: FetchTVDetailsUseCase {
        var result: Result<TVShowDetailsBundle, Error> = .failure(MockError.stubbed)
        private(set) var requestedIDs: [Int] = []

        func execute(showID: Int) async throws -> TVShowDetailsBundle {
            requestedIDs.append(showID)
            return try result.get()
        }
    }

    private let mock = FetchMock()

    private func makeViewModel() throws -> TVDetailsViewModel {
        try TVDetailsViewModel(showID: 1396, fetchDetails: mock, imageBaseURL: #require(URL(string: "https://img.invalid/t/p")))
    }

    private func bundle() -> TVShowDetailsBundle {
        TVShowDetailsBundle(
            details: TVShowDetails(
                id: 1396,
                name: "Breaking Bad",
                overview: "…",
                firstAirDate: Calendar(identifier: .gregorian).date(from: DateComponents(year: 2008, month: 1, day: 20)),
                numberOfSeasons: 5,
                numberOfEpisodes: 62
            ),
            similar: [MediaItem(id: 1400, mediaType: .tv, title: "The Sopranos", overview: "")]
        )
    }

    @Test("load lands in .loaded and requests the screen's show")
    func loadSuccess() async throws {
        mock.result = .success(bundle())
        let viewModel = try makeViewModel()

        await viewModel.load()

        #expect(viewModel.state == .loaded(bundle()))
        #expect(mock.requestedIDs == [1396])
    }

    @Test("load is idempotent once loaded")
    func idempotent() async throws {
        mock.result = .success(bundle())
        let viewModel = try makeViewModel()
        await viewModel.load()

        await viewModel.load()

        #expect(mock.requestedIDs == [1396])
    }

    @Test("failure lands in .error; load retries out of it")
    func failureAndRetry() async throws {
        let viewModel = try makeViewModel()
        await viewModel.load()

        guard case .error = viewModel.state else {
            Issue.record("expected .error")
            return
        }
        mock.result = .success(bundle())
        await viewModel.load()
        #expect(viewModel.state == .loaded(bundle()))
    }

    @Test("cancellation returns to idle, not error")
    func cancellation() async throws {
        mock.result = .failure(CancellationError())
        let viewModel = try makeViewModel()

        await viewModel.load()

        #expect(viewModel.state == .idle)
    }

    @Test("metadata line joins year, seasons, and episodes")
    func metadataLine() throws {
        let viewModel = try makeViewModel()

        let line = viewModel.metadata(for: bundle().details)

        #expect(line == "2008 · 5 seasons · 62 episodes")
    }

    @Test("metadata singularizes a one-season show and omits empty parts")
    func metadataSingularAndSparse() throws {
        let viewModel = try makeViewModel()
        let details = TVShowDetails(id: 1, name: "S", overview: "", numberOfSeasons: 1, numberOfEpisodes: 0)

        #expect(viewModel.metadata(for: details) == "1 season")
    }

    @Test("backdrop URL uses w780, falling back to the poster")
    func backdropURL() throws {
        let viewModel = try makeViewModel()
        let withBackdrop = TVShowDetails(id: 1, name: "A", overview: "", backdropPath: "/b.jpg")
        let posterOnly = TVShowDetails(id: 2, name: "B", overview: "", posterPath: "/p.jpg")

        #expect(viewModel.backdropURL(for: withBackdrop)?.absoluteString == "https://img.invalid/t/p/w780/b.jpg")
        #expect(viewModel.backdropURL(for: posterOnly)?.absoluteString == "https://img.invalid/t/p/w780/p.jpg")
    }
}
