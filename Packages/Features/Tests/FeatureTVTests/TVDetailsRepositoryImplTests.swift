//
//  TVDetailsRepositoryImplTests.swift
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

/// TV details repository through the real client against a stubbed
/// `URLProtocol`: routing, appended-payload decoding, TV-specific fields, and
/// related carousels mapped to the shared MediaItem.
@Suite("TVDetailsRepositoryImpl")
struct TVDetailsRepositoryImplTests {
    private let stub: URLProtocolStub.Handle
    private let repository: TVDetailsRepositoryImpl

    init() throws {
        let (session, stub) = URLProtocolStub.makeSession()
        self.stub = stub
        let baseURL = try #require(URL(string: "https://stub.invalid/3"))
        repository = TVDetailsRepositoryImpl(apiClient: URLSessionAPIClient(baseURL: baseURL, session: session))
    }

    @Test("decodes the appended TV payload into a full bundle on the right route")
    func fullBundle() async throws {
        stub.stub(data: Data("""
        {
            "id": 1396,
            "name": "Breaking Bad",
            "overview": "A high school chemistry teacher…",
            "tagline": "Change the equation.",
            "poster_path": "/bb.jpg",
            "backdrop_path": "/bb_back.jpg",
            "first_air_date": "2008-01-20",
            "number_of_seasons": 5,
            "number_of_episodes": 62,
            "vote_average": 8.9,
            "vote_count": 12000,
            "genres": [{"id": 18, "name": "Drama"}, {"id": 80, "name": "Crime"}],
            "similar": {"page": 1, "results": [{"id": 1400, "name": "The Sopranos"}], "total_pages": 1},
            "recommendations": {"page": 1, "results": [{"id": 60059, "name": "Better Call Saul"}], "total_pages": 1}
        }
        """.utf8))

        let bundle = try await repository.detailsBundle(for: 1396)

        #expect(bundle.details.id == 1396)
        #expect(bundle.details.name == "Breaking Bad")
        #expect(bundle.details.tagline == "Change the equation.")
        #expect(bundle.details.numberOfSeasons == 5)
        #expect(bundle.details.numberOfEpisodes == 62)
        #expect(bundle.details.genres == ["Drama", "Crime"])
        #expect(bundle.similar.map(\.id) == [1400])
        #expect(bundle.similar.first?.mediaType == .tv, "related shows are TV MediaItems")
        #expect(bundle.similar.first?.title == "The Sopranos")
        #expect(bundle.recommendations.map(\.id) == [60059])

        let url = try #require(stub.lastRequest?.url)
        #expect(url.path() == "/3/tv/1396")
        let comps = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        #expect(comps.queryItems == [URLQueryItem(name: "append_to_response", value: "similar,recommendations")])
    }

    @Test("a bare payload maps to an empty-but-valid bundle")
    func barePayload() async throws {
        stub.stub(data: Data(#"{"id": 1, "name": "Show"}"#.utf8))

        let bundle = try await repository.detailsBundle(for: 1)

        #expect(bundle.details.name == "Show")
        #expect(bundle.details.overview.isEmpty)
        #expect(bundle.details.tagline == nil)
        #expect(bundle.details.numberOfSeasons == 0)
        #expect(bundle.similar.isEmpty)
        #expect(bundle.recommendations.isEmpty)
    }

    @Test("empty tagline normalizes to nil")
    func emptyTagline() async throws {
        stub.stub(data: Data(#"{"id": 1, "name": "S", "tagline": ""}"#.utf8))

        let bundle = try await repository.detailsBundle(for: 1)

        #expect(bundle.details.tagline == nil)
    }

    @Test("the use case delegates to the repository")
    func useCaseDelegates() async throws {
        stub.stub(data: Data(#"{"id": 42, "name": "X"}"#.utf8))
        let useCase = FetchTVDetailsUseCaseImpl(repository: repository)

        let bundle = try await useCase.execute(showID: 42)

        #expect(bundle.details.id == 42)
    }

    @Test("HTTP 404 surfaces as APIError.notFound")
    func notFound() async {
        stub.stub(statusCode: 404, data: Data(#"{"status_code": 34}"#.utf8))

        do {
            _ = try await repository.detailsBundle(for: 999_999)
            Issue.record("expected APIError.notFound")
        } catch APIError.notFound {
            // expected
        } catch {
            Issue.record("expected APIError.notFound, got \(error)")
        }
    }
}
