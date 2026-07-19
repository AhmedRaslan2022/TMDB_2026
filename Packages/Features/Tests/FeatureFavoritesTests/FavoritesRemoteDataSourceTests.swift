//
//  FavoritesRemoteDataSourceTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 19/07/2026.
//

import CoreModels
import Foundation
import Networking
import SharedTestSupport
import Testing
@testable import FeatureFavorites

@Suite("FavoritesRemoteDataSource")
struct FavoritesRemoteDataSourceTests {
    private let stub: URLProtocolStub.Handle
    private let dataSource: FavoritesRemoteDataSourceImpl
    private let account = FavoritesAccount(accountID: 42, sessionID: "sess-123")

    init() throws {
        let (session, stub) = URLProtocolStub.makeSession()
        self.stub = stub
        let baseURL = try #require(URL(string: "https://stub.invalid/3"))
        dataSource = FavoritesRemoteDataSourceImpl(
            apiClient: URLSessionAPIClient(baseURL: baseURL, session: session)
        )
    }

    @Test("list decodes the account favorites page and targets the right route")
    func list() async throws {
        stub.stub(data: Data("""
        {"page": 1, "results": [
            {"id": 550, "title": "Fight Club", "poster_path": "/p.jpg", "vote_average": 8.4}
        ], "total_pages": 3}
        """.utf8))

        let page = try await dataSource.favorites(account: account, page: 1)

        #expect(page.movies.map(\.id) == [550])
        #expect(page.hasMorePages)
        let url = try #require(stub.lastRequest?.url)
        #expect(url.path() == "/3/account/42/favorite/movies")
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        #expect(components.queryItems == [
            URLQueryItem(name: "session_id", value: "sess-123"),
            URLQueryItem(name: "page", value: "1"),
            URLQueryItem(name: "sort_by", value: "created_at.desc"),
        ])
        #expect(stub.lastRequest?.httpMethod == "GET")
    }

    @Test("mapping parses release_date and fills missing optionals leniently")
    func mapping() async throws {
        stub.stub(data: Data("""
        {"page": 1, "results": [
            {"id": 550, "title": "Fight Club", "release_date": "1999-10-15", "vote_average": 8.4}
        ], "total_pages": 1}
        """.utf8))

        let movie = try #require(try await dataSource.favorites(account: account, page: 1).movies.first)

        #expect(movie.overview.isEmpty)
        #expect(movie.genreIDs.isEmpty)
        #expect(movie.voteAverage == 8.4)
        var components = DateComponents(year: 1999, month: 10, day: 15)
        components.timeZone = TimeZone(identifier: "UTC")
        #expect(movie.releaseDate == Calendar(identifier: .gregorian).date(from: components))
    }

    @Test("setFavorite POSTs to the favorite route with the session query")
    func setFavorite() async throws {
        // Body content is asserted at the endpoint level — URLProtocol moves
        // httpBody to a stream, so the recorded request's body is unreliable.
        stub.stub(data: Data(#"{"success": true, "status_code": 1}"#.utf8))

        try await dataSource.setFavorite(account: account, movieID: 550, isFavorite: true)

        let request = try #require(stub.lastRequest)
        let url = try #require(request.url)
        #expect(url.path() == "/3/account/42/favorite")
        #expect(request.httpMethod == "POST")
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        #expect(components.queryItems == [URLQueryItem(name: "session_id", value: "sess-123")])
    }

    @Test("HTTP 401 surfaces as APIError.unauthorized")
    func unauthorized() async {
        stub.stub(statusCode: 401, data: Data(#"{"status_code": 3}"#.utf8))

        do {
            _ = try await dataSource.favorites(account: account, page: 1)
            Issue.record("expected APIError.unauthorized")
        } catch APIError.unauthorized {
            // expected
        } catch {
            Issue.record("expected APIError.unauthorized, got \(error)")
        }
    }
}
