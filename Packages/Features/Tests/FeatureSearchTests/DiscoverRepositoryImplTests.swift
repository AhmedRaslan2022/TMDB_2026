//
//  DiscoverRepositoryImplTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

import CoreModels
import Foundation
import Networking
import SharedTestSupport
import Testing
@testable import FeatureSearch

/// Repository + data source through the real client against a stubbed
/// `URLProtocol`: genre + discover routing, decoding, mapping, errors.
@Suite("DiscoverRepositoryImpl")
struct DiscoverRepositoryImplTests {
    private let stub: URLProtocolStub.Handle
    private let repository: DiscoverRepositoryImpl

    init() throws {
        let (session, stub) = URLProtocolStub.makeSession()
        self.stub = stub
        let baseURL = try #require(URL(string: "https://stub.invalid/3"))
        repository = DiscoverRepositoryImpl(
            apiClient: URLSessionAPIClient(baseURL: baseURL, session: session)
        )
    }

    @Test("genres() decodes the catalog and hits the genre route")
    func decodesGenres() async throws {
        stub.stub(data: Data(#"{"genres": [{"id": 28, "name": "Action"}, {"id": 35, "name": "Comedy"}]}"#.utf8))

        let genres = try await repository.genres()

        #expect(genres == [MovieGenre(id: 28, name: "Action"), MovieGenre(id: 35, name: "Comedy")])
        #expect(stub.lastRequest?.url?.path() == "/3/genre/movie/list")
    }

    @Test("discover() decodes a result page and hits the discover route with filter query items")
    func decodesDiscover() async throws {
        stub.stub(data: Data("""
        {
            "page": 1,
            "results": [{"id": 603, "title": "The Matrix", "poster_path": "/m.jpg", "vote_average": 8.2, "vote_count": 20000}],
            "total_pages": 3
        }
        """.utf8))

        let page = try await repository.discover(
            filters: DiscoverFilters(genreIDs: [28], minimumRating: 8, sort: .rating),
            page: 1
        )

        #expect(page.movies.map(\.id) == [603])
        #expect(page.hasMorePages)
        let url = try #require(stub.lastRequest?.url)
        #expect(url.path() == "/3/discover/movie")
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let items = try #require(components.queryItems)
        #expect(items.contains(URLQueryItem(name: "with_genres", value: "28")))
        #expect(items.contains(URLQueryItem(name: "sort_by", value: "vote_average.desc")))
        #expect(items.contains(URLQueryItem(name: "vote_count.gte", value: "200")))
    }

    @Test("HTTP 401 surfaces as APIError.unauthorized")
    func unauthorized() async {
        stub.stub(statusCode: 401, data: Data(#"{"status_code": 7}"#.utf8))

        do {
            _ = try await repository.discover(filters: DiscoverFilters(), page: 1)
            Issue.record("expected APIError.unauthorized")
        } catch APIError.unauthorized {
            // expected
        } catch {
            Issue.record("expected APIError.unauthorized, got \(error)")
        }
    }
}
