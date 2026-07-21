//
//  PersonViewModelTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 21/07/2026.
//

import CoreModels
import Foundation
import Testing
@testable import FeaturePerson

@MainActor
@Suite("PersonViewModel")
struct PersonViewModelTests {
    private enum MockError: Error { case stubbed }

    @MainActor
    private final class FetchMock: FetchPersonDetailsUseCase {
        var result: Result<PersonDetailsBundle, Error> = .failure(MockError.stubbed)
        private(set) var requestedIDs: [Int] = []

        func execute(personID: Int) async throws -> PersonDetailsBundle {
            requestedIDs.append(personID)
            return try result.get()
        }
    }

    private let mock = FetchMock()

    private func makeViewModel() throws -> PersonViewModel {
        try PersonViewModel(personID: 287, fetchDetails: mock, imageBaseURL: #require(URL(string: "https://img.invalid/t/p")))
    }

    private func bundle() -> PersonDetailsBundle {
        PersonDetailsBundle(
            person: Person(
                id: 287,
                name: "Brad Pitt",
                biography: "…",
                birthday: Calendar(identifier: .gregorian).date(from: DateComponents(year: 1963, month: 12, day: 18)),
                placeOfBirth: "Shawnee, Oklahoma, USA",
                profilePath: "/pitt.jpg",
                knownForDepartment: "Acting"
            ),
            filmography: [PersonCredit(media: MediaItem(id: 550, title: "Fight Club", overview: "", posterPath: "/fc.jpg"))]
        )
    }

    @Test("load lands in .loaded and requests the screen's person")
    func loadSuccess() async throws {
        mock.result = .success(bundle())
        let viewModel = try makeViewModel()

        await viewModel.load()

        #expect(viewModel.state == .loaded(bundle()))
        #expect(mock.requestedIDs == [287])
    }

    @Test("load is idempotent once loaded")
    func idempotent() async throws {
        mock.result = .success(bundle())
        let viewModel = try makeViewModel()
        await viewModel.load()

        await viewModel.load()

        #expect(mock.requestedIDs == [287])
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

    @Test("headshot and poster URLs use their size buckets")
    func imageURLs() throws {
        let viewModel = try makeViewModel()
        let person = bundle().person
        let credit = try #require(bundle().filmography.first)

        #expect(viewModel.headshotURL(for: person)?.absoluteString == "https://img.invalid/t/p/w185/pitt.jpg")
        #expect(viewModel.posterURL(for: credit)?.absoluteString == "https://img.invalid/t/p/w342/fc.jpg")
    }

    @Test("birth line joins the birthday and place, omitting missing parts")
    func birthLine() throws {
        let viewModel = try makeViewModel()

        let line = viewModel.birthLine(for: bundle().person)

        #expect(line.contains("1963"))
        #expect(line.contains("Shawnee, Oklahoma, USA"))
        #expect(line.contains(" · "))

        let sparse = Person(id: 1, name: "N", biography: "")
        #expect(viewModel.birthLine(for: sparse).isEmpty)
    }
}
