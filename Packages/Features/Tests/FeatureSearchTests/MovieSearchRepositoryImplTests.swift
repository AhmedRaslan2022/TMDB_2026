//
//  MovieSearchRepositoryImplTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 19/07/2026.
//

import CoreModels
import Foundation
import Networking
import SharedTestSupport
import Testing
@testable import FeatureSearch

/// Repository + data source through the real client against a stubbed
/// `URLProtocol`: routing, query encoding, decoding, mapping, errors.
@Suite("MovieSearchRepositoryImpl")
struct MovieSearchRepositoryImplTests {
    private let stub: URLProtocolStub.Handle
    private let repository: MovieSearchRepositoryImpl

    init() throws {
        let (session, stub) = URLProtocolStub.makeSession()
        self.stub = stub
        let baseURL = try #require(URL(string: "https://stub.invalid/3"))
        repository = MovieSearchRepositoryImpl(
            apiClient: URLSessionAPIClient(baseURL: baseURL, session: session)
        )
    }

    @Test("decodes a result page and hits the search route with the right query items")
    func decodesAndRoutes() async throws {
        stub.stub(data: Data("""
        {
            "page": 1,
            "results": [{
                "id": 550,
                "title": "Fight Club",
                "poster_path": "/poster.jpg",
                "release_date": "1999-10-15",
                "vote_average": 8.4,
                "vote_count": 30000
            }],
            "total_pages": 2
        }
        """.utf8))

        let page = try await repository.search(query: "fight club", page: 1)

        #expect(page.movies.map(\.id) == [550])
        #expect(page.movies.first?.posterPath == "/poster.jpg")
        #expect(page.hasMorePages)

        let url = try #require(stub.lastRequest?.url)
        #expect(url.path() == "/3/search/movie")
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        #expect(components.queryItems == [
            URLQueryItem(name: "query", value: "fight club"),
            URLQueryItem(name: "page", value: "1"),
            URLQueryItem(name: "include_adult", value: "false"),
        ])
    }

    @Test("queries with spaces and unicode survive URL encoding")
    func queryEncoding() async throws {
        stub.stub(data: Data(#"{"page": 1, "results": [], "total_pages": 1}"#.utf8))

        _ = try await repository.search(query: "أفلام رعب & more", page: 3)

        let url = try #require(stub.lastRequest?.url)
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        #expect(components.queryItems?.first(where: { $0.name == "query" })?.value == "أفلام رعب & more")
        #expect(components.queryItems?.first(where: { $0.name == "page" })?.value == "3")
    }

    @Test("no results maps to an empty page without more pages")
    func emptyResults() async throws {
        stub.stub(data: Data(#"{"page": 1, "results": [], "total_pages": 1}"#.utf8))

        let page = try await repository.search(query: "zzzzz", page: 1)

        #expect(page.movies.isEmpty)
        #expect(!page.hasMorePages)
    }

    @Test("HTTP 401 surfaces as APIError.unauthorized")
    func unauthorized() async {
        stub.stub(statusCode: 401, data: Data(#"{"status_code": 7}"#.utf8))

        do {
            _ = try await repository.search(query: "x", page: 1)
            Issue.record("expected APIError.unauthorized")
        } catch APIError.unauthorized {
            // expected
        } catch {
            Issue.record("expected APIError.unauthorized, got \(error)")
        }
    }
}
