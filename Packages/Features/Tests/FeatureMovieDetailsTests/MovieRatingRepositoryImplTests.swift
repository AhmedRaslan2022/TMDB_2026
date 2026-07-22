//
//  MovieRatingRepositoryImplTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

import Foundation
import Networking
import SharedTestSupport
import Testing
@testable import FeatureMovieDetails

/// The rating repository through the real client against a stubbed
/// `URLProtocol`: routing, `account_states` decoding, and the no-session guard.
@Suite("MovieRatingRepositoryImpl")
struct MovieRatingRepositoryImplTests {
    private final class SessionProviderMock: MovieRatingSessionProviding {
        let stored: String?
        init(sessionID: String?) {
            stored = sessionID
        }

        func sessionID() async -> String? {
            stored
        }
    }

    private func makeRepository(
        session: String?
    ) throws -> (MovieRatingRepositoryImpl, URLProtocolStub.Handle) {
        let (urlSession, stub) = URLProtocolStub.makeSession()
        let baseURL = try #require(URL(string: "https://stub.invalid/3"))
        let repository = MovieRatingRepositoryImpl(
            apiClient: URLSessionAPIClient(baseURL: baseURL, session: urlSession),
            sessionProvider: SessionProviderMock(sessionID: session)
        )
        return (repository, stub)
    }

    @Test("rating() decodes the rated object and hits account_states with the session query")
    func readsExistingRating() async throws {
        let (repository, stub) = try makeRepository(session: "sess")
        stub.stub(data: Data(#"{"id": 550, "favorite": false, "rated": {"value": 8.0}, "watchlist": false}"#.utf8))

        let value = try await repository.rating(movieID: 550)

        #expect(value == 8.0)
        let request = try #require(stub.lastRequest)
        #expect(request.httpMethod == "GET")
        let url = try #require(request.url)
        #expect(url.path() == "/3/movie/550/account_states")
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        #expect(components.queryItems?.contains(URLQueryItem(name: "session_id", value: "sess")) == true)
    }

    @Test("rating() maps `rated: false` to nil (unrated)")
    func unratedIsNil() async throws {
        let (repository, stub) = try makeRepository(session: "sess")
        stub.stub(data: Data(#"{"id": 550, "favorite": false, "rated": false, "watchlist": false}"#.utf8))

        #expect(try await repository.rating(movieID: 550) == nil)
    }

    @Test("rating() maps an absent `rated` key to nil (unrated)")
    func absentRatedIsNil() async throws {
        let (repository, stub) = try makeRepository(session: "sess")
        stub.stub(data: Data(#"{"id": 550, "favorite": false, "watchlist": false}"#.utf8))

        #expect(try await repository.rating(movieID: 550) == nil)
    }

    @Test("rating() degrades a malformed `rated` object to nil rather than throwing")
    func malformedRatedIsNil() async throws {
        let (repository, stub) = try makeRepository(session: "sess")
        stub.stub(data: Data(#"{"id": 550, "rated": {"value": "not-a-number"}}"#.utf8))

        #expect(try await repository.rating(movieID: 550) == nil)
    }

    @Test("rating() returns nil without hitting the network when there's no session")
    func noSessionSkipsRead() async throws {
        let (repository, stub) = try makeRepository(session: nil)

        #expect(try await repository.rating(movieID: 550) == nil)
        #expect(stub.requestCount == 0)
    }

    @Test("setRating(value) POSTs to /rating")
    func writesRating() async throws {
        let (repository, stub) = try makeRepository(session: "sess")
        stub.stub(statusCode: 201, data: Data(#"{"success": true}"#.utf8))

        try await repository.setRating(8, movieID: 550)

        let request = try #require(stub.lastRequest)
        #expect(request.httpMethod == "POST")
        #expect(request.url?.path() == "/3/movie/550/rating")
    }

    @Test("setRating(nil) DELETEs the rating")
    func deletesRating() async throws {
        let (repository, stub) = try makeRepository(session: "sess")
        stub.stub(data: Data(#"{"success": true}"#.utf8))

        try await repository.setRating(nil, movieID: 550)

        let request = try #require(stub.lastRequest)
        #expect(request.httpMethod == "DELETE")
        #expect(request.url?.path() == "/3/movie/550/rating")
    }

    @Test("setRating without a session throws notAuthenticated and never calls the network")
    func writeWithoutSessionThrows() async throws {
        let (repository, stub) = try makeRepository(session: nil)

        await #expect(throws: MovieRatingError.notAuthenticated) {
            try await repository.setRating(8, movieID: 550)
        }
        #expect(stub.requestCount == 0)
    }
}
