//
//  MovieListRepositoryImplTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 18/07/2026.
//

import CoreModels
import Foundation
import Networking
import SharedTestSupport
import Testing
@testable import FeatureHome

/// Repository + data source exercised together through the real
/// `URLSessionAPIClient` against a stubbed `URLProtocol` — covers routing,
/// decoding, mapping and error surfacing in one pass.
@Suite("MovieListRepositoryImpl")
struct MovieListRepositoryImplTests {
    private let stub: URLProtocolStub.Handle
    private let repository: MovieListRepositoryImpl

    init() throws {
        let (session, stub) = URLProtocolStub.makeSession()
        self.stub = stub
        let baseURL = try #require(URL(string: "https://stub.invalid/3"))
        repository = MovieListRepositoryImpl(
            apiClient: URLSessionAPIClient(baseURL: baseURL, session: session)
        )
    }

    @Test("decodes TMDB's snake_case page and maps it to domain")
    func decodesAndMaps() async throws {
        stub.stub(data: Data("""
        {
            "page": 1,
            "results": [{
                "id": 550,
                "title": "Fight Club",
                "overview": "An insomniac office worker…",
                "poster_path": "/poster.jpg",
                "backdrop_path": "/backdrop.jpg",
                "release_date": "1999-10-15",
                "vote_average": 8.4,
                "vote_count": 30000,
                "genre_ids": [18, 53]
            }],
            "total_pages": 500
        }
        """.utf8))

        let page = try await repository.movies(in: .popular, page: 1)

        #expect(page.page == 1)
        #expect(page.totalPages == 500)
        let movie = try #require(page.movies.first)
        #expect(movie.id == 550)
        #expect(movie.posterPath == "/poster.jpg")
        #expect(movie.genreIDs == [18, 53])
        let request = try #require(stub.lastRequest)
        let url = try #require(request.url)
        #expect(url.path() == "/3/movie/popular")
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        #expect(components.queryItems == [URLQueryItem(name: "page", value: "1")])
    }

    @Test("trending window rides in the path")
    func trendingRoute() async throws {
        stub.stub(data: Data(#"{"page": 1, "results": [], "total_pages": 1}"#.utf8))

        _ = try await repository.movies(in: .trending(.week), page: 1)

        #expect(stub.lastRequest?.url?.path() == "/3/trending/movie/week")
    }

    @Test("HTTP 401 surfaces as APIError.unauthorized")
    func unauthorized() async {
        stub.stub(statusCode: 401, data: Data(#"{"status_code": 7}"#.utf8))

        do {
            _ = try await repository.movies(in: .popular, page: 1)
            Issue.record("expected APIError.unauthorized")
        } catch APIError.unauthorized {
            // expected
        } catch {
            Issue.record("expected APIError.unauthorized, got \(error)")
        }
    }

    @Test("malformed payload surfaces as APIError.decoding")
    func decodingFailure() async {
        stub.stub(data: Data(#"{"page": "one"}"#.utf8))

        do {
            _ = try await repository.movies(in: .popular, page: 1)
            Issue.record("expected APIError.decoding")
        } catch APIError.decoding {
            // expected
        } catch {
            Issue.record("expected APIError.decoding, got \(error)")
        }
    }
}
