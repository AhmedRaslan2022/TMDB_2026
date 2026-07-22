//
//  TVListRepositoryImplTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 21/07/2026.
//

import CoreModels
import Foundation
import Networking
import SharedTestSupport
import Testing
@testable import FeatureTV

/// TV list repository through the real client against a stubbed `URLProtocol`:
/// routing per list, decoding, and the TV→MediaItem normalization.
@Suite("TVListRepositoryImpl")
struct TVListRepositoryImplTests {
    private let stub: URLProtocolStub.Handle
    private let repository: TVListRepositoryImpl

    init() throws {
        let (session, stub) = URLProtocolStub.makeSession()
        self.stub = stub
        let baseURL = try #require(URL(string: "https://stub.invalid/3"))
        repository = TVListRepositoryImpl(apiClient: URLSessionAPIClient(baseURL: baseURL, session: session))
    }

    @Test("each list routes to its TMDB path", arguments: [
        (TVList.onTheAir, "/3/tv/on_the_air"),
        (TVList.popular, "/3/tv/popular"),
        (TVList.topRated, "/3/tv/top_rated"),
    ])
    func routing(list: TVList, expectedPath: String) async throws {
        stub.stub(data: Data(#"{"page": 1, "results": [], "total_pages": 1}"#.utf8))

        _ = try await repository.shows(in: list, page: 1)

        #expect(stub.lastRequest?.url?.path() == expectedPath)
    }

    @Test("decodes a page and normalizes TV fields into MediaItem(.tv)")
    func decodesAndNormalizes() async throws {
        stub.stub(data: Data("""
        {
            "page": 1,
            "results": [{
                "id": 1399,
                "name": "Game of Thrones",
                "overview": "Nine noble families…",
                "poster_path": "/got.jpg",
                "first_air_date": "2011-04-17",
                "vote_average": 8.4,
                "vote_count": 20000,
                "genre_ids": [18, 10765]
            }],
            "total_pages": 3
        }
        """.utf8))

        let page = try await repository.shows(in: .popular, page: 1)

        let show = try #require(page.movies.first)
        #expect(show.mediaType == .tv)
        #expect(show.title == "Game of Thrones", "TV name maps to the shared title")
        #expect(show.posterPath == "/got.jpg")
        #expect(show.genreIDs == [18, 10765])
        #expect(show.voteAverage == 8.4)
        var comps = DateComponents(year: 2011, month: 4, day: 17)
        comps.timeZone = TimeZone(identifier: "UTC")
        #expect(show.releaseDate == Calendar(identifier: .gregorian).date(from: comps), "first_air_date maps to releaseDate")
        #expect(page.hasMorePages)
        #expect(stub.lastRequest?.url?.query()?.contains("page=1") == true)
    }

    @Test("the use case delegates to the repository")
    func useCaseDelegates() async throws {
        stub.stub(data: Data(#"{"page": 2, "results": [], "total_pages": 5}"#.utf8))
        let useCase = FetchTVListUseCaseImpl(repository: repository)

        let page = try await useCase.execute(list: .topRated, page: 2)

        #expect(page.page == 2)
        #expect(page.hasMorePages)
    }

    @Test("HTTP 401 surfaces as APIError.unauthorized")
    func unauthorized() async {
        stub.stub(statusCode: 401, data: Data(#"{"status_code": 7}"#.utf8))

        do {
            _ = try await repository.shows(in: .popular, page: 1)
            Issue.record("expected APIError.unauthorized")
        } catch APIError.unauthorized {
            // expected
        } catch {
            Issue.record("expected APIError.unauthorized, got \(error)")
        }
    }
}
