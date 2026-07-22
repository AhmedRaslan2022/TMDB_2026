//
//  ProfileRemoteDataSourceTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

import Foundation
import Networking
import SharedTestSupport
import Testing
@testable import FeatureProfile

@Suite("ProfileRemoteDataSource")
struct ProfileRemoteDataSourceTests {
    private let stub: URLProtocolStub.Handle
    private let dataSource: ProfileRemoteDataSourceImpl

    init() throws {
        let (session, stub) = URLProtocolStub.makeSession()
        self.stub = stub
        let baseURL = try #require(URL(string: "https://stub.invalid/3"))
        dataSource = ProfileRemoteDataSourceImpl(
            apiClient: URLSessionAPIClient(baseURL: baseURL, session: session)
        )
    }

    @Test("account decodes the nested avatar and hits /account with the session")
    func account() async throws {
        stub.stub(data: Data("""
        {
            "id": 42,
            "username": "ada",
            "name": "Ada Lovelace",
            "avatar": {"tmdb": {"avatar_path": "/a.jpg"}, "gravatar": {"hash": "abc123"}}
        }
        """.utf8))

        let dto = try await dataSource.account(sessionID: "sess-1")

        #expect(dto.id == 42)
        #expect(dto.username == "ada")
        #expect(dto.avatar?.tmdb?.avatarPath == "/a.jpg")
        #expect(dto.avatar?.gravatar?.hash == "abc123")
        let url = try #require(stub.lastRequest?.url)
        #expect(url.path() == "/3/account")
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        #expect(components.queryItems == [URLQueryItem(name: "session_id", value: "sess-1")])
    }

    @Test("favorite count reads total_results from the favorites list route")
    func favoriteCount() async throws {
        stub.stub(data: Data(#"{"page": 1, "results": [], "total_results": 37, "total_pages": 2}"#.utf8))

        let count = try await dataSource.favoriteCount(accountID: 42, sessionID: "sess-1")

        #expect(count == 37)
        #expect(stub.lastRequest?.url?.path() == "/3/account/42/favorite/movies")
    }

    @Test("watchlist count reads total_results from the watchlist route")
    func watchlistCount() async throws {
        stub.stub(data: Data(#"{"page": 1, "results": [], "total_results": 8, "total_pages": 1}"#.utf8))

        let count = try await dataSource.watchlistCount(accountID: 42, sessionID: "sess-1")

        #expect(count == 8)
        #expect(stub.lastRequest?.url?.path() == "/3/account/42/watchlist/movies")
    }

    @Test("HTTP 401 surfaces as APIError.unauthorized")
    func unauthorized() async {
        stub.stub(statusCode: 401, data: Data(#"{"status_code": 3}"#.utf8))

        do {
            _ = try await dataSource.account(sessionID: "bad")
            Issue.record("expected APIError.unauthorized")
        } catch APIError.unauthorized {
            // expected
        } catch {
            Issue.record("expected APIError.unauthorized, got \(error)")
        }
    }
}
