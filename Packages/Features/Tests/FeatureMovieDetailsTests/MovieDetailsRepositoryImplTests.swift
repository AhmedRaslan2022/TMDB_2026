//
//  MovieDetailsRepositoryImplTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 19/07/2026.
//

import CoreModels
import Foundation
import Networking
import SharedTestSupport
import Testing
@testable import FeatureMovieDetails

/// Repository + data source through the real client against a stubbed
/// `URLProtocol`: routing, appended-payload decoding, mapping, errors.
@Suite("MovieDetailsRepositoryImpl")
struct MovieDetailsRepositoryImplTests {
    private let stub: URLProtocolStub.Handle
    private let repository: MovieDetailsRepositoryImpl

    init() throws {
        let (session, stub) = URLProtocolStub.makeSession()
        self.stub = stub
        let baseURL = try #require(URL(string: "https://stub.invalid/3"))
        repository = MovieDetailsRepositoryImpl(
            apiClient: URLSessionAPIClient(baseURL: baseURL, session: session)
        )
    }

    private static let fullPayload = """
    {
        "id": 550,
        "title": "Fight Club",
        "overview": "An insomniac office worker…",
        "tagline": "Mischief. Mayhem. Soap.",
        "poster_path": "/poster.jpg",
        "backdrop_path": "/backdrop.jpg",
        "release_date": "1999-10-15",
        "runtime": 139,
        "vote_average": 8.4,
        "vote_count": 30000,
        "genres": [{"id": 18, "name": "Drama"}, {"id": 53, "name": "Thriller"}],
        "credits": {
            "cast": [
                {"credit_id": "c2", "id": 819, "name": "Edward Norton",
                 "character": "The Narrator", "profile_path": "/norton.jpg", "order": 1},
                {"credit_id": "c1", "id": 287, "name": "Brad Pitt",
                 "character": "Tyler Durden", "profile_path": "/pitt.jpg", "order": 0}
            ]
        },
        "videos": {
            "results": [
                {"id": "v1", "name": "Trailer 1", "key": "abc123", "site": "YouTube", "type": "Trailer", "official": true},
                {"id": "v2", "name": "Weird upload", "key": "zzz", "site": "MySpace", "type": "Clip"}
            ]
        },
        "similar": {"results": [{"id": 807, "title": "Se7en", "poster_path": "/se7en.jpg"}]},
        "recommendations": {"results": [{"id": 680, "title": "Pulp Fiction"}]}
    }
    """

    @Test("decodes the appended payload into a full bundle, hitting the right route")
    func fullBundle() async throws {
        stub.stub(data: Data(Self.fullPayload.utf8))

        let bundle = try await repository.detailsBundle(for: 550)

        #expect(bundle.details.id == 550)
        #expect(bundle.details.tagline == "Mischief. Mayhem. Soap.")
        #expect(bundle.details.runtimeMinutes == 139)
        #expect(bundle.details.genres.map(\.name) == ["Drama", "Thriller"])
        #expect(bundle.details.posterPath == "/poster.jpg")
        var components = DateComponents(year: 1999, month: 10, day: 15)
        components.timeZone = TimeZone(identifier: "UTC")
        #expect(bundle.details.releaseDate == Calendar(identifier: .gregorian).date(from: components))
        #expect(bundle.similar.map(\.id) == [807])
        #expect(bundle.similar.first?.posterPath == "/se7en.jpg")
        #expect(bundle.recommendations.map(\.id) == [680])

        let request = try #require(stub.lastRequest)
        let url = try #require(request.url)
        #expect(url.path() == "/3/movie/550")
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        #expect(components.queryItems == [
            URLQueryItem(name: "append_to_response", value: "credits,videos,similar,recommendations"),
        ])
    }

    @Test("cast comes out in billing order regardless of payload order")
    func castBillingOrder() async throws {
        stub.stub(data: Data(Self.fullPayload.utf8))

        let bundle = try await repository.detailsBundle(for: 550)

        #expect(bundle.cast.map(\.name) == ["Brad Pitt", "Edward Norton"])
        #expect(bundle.cast.first?.id == "c1")
        #expect(bundle.cast.first?.personID == 287)
        #expect(bundle.cast.first?.profilePath == "/pitt.jpg")
    }

    @Test("the use case delegates to the repository")
    func useCaseDelegates() async throws {
        stub.stub(data: Data(Self.fullPayload.utf8))
        let useCase = FetchMovieDetailsUseCaseImpl(repository: repository)

        let bundle = try await useCase.execute(movieID: 550)

        #expect(bundle.details.id == 550)
    }

    @Test("videos from unknown sites are dropped; known ones keep their metadata")
    func videoSiteFiltering() async throws {
        stub.stub(data: Data(Self.fullPayload.utf8))

        let bundle = try await repository.detailsBundle(for: 550)

        #expect(bundle.videos.count == 1)
        let video = try #require(bundle.videos.first)
        #expect(video.site == .youTube)
        #expect(video.isTrailer)
        #expect(video.isOfficial)
    }

    @Test("a bare payload (no appended sections) maps to an empty-but-valid bundle")
    func barePayload() async throws {
        stub.stub(data: Data(#"{"id": 550, "title": "Fight Club"}"#.utf8))

        let bundle = try await repository.detailsBundle(for: 550)

        #expect(bundle.details.title == "Fight Club")
        #expect(bundle.details.overview.isEmpty)
        #expect(bundle.details.releaseDate == nil)
        #expect(bundle.cast.isEmpty)
        #expect(bundle.videos.isEmpty)
        #expect(bundle.similar.isEmpty)
        #expect(bundle.recommendations.isEmpty)
    }

    @Test("empty tagline and zero runtime normalize to nil")
    func emptyFieldNormalization() async throws {
        stub.stub(data: Data(#"{"id": 1, "title": "X", "tagline": "", "runtime": 0}"#.utf8))

        let bundle = try await repository.detailsBundle(for: 1)

        #expect(bundle.details.tagline == nil)
        #expect(bundle.details.runtimeMinutes == nil)
    }

    @Test("HTTP 404 surfaces as APIError.notFound")
    func notFound() async {
        stub.stub(statusCode: 404, data: Data(#"{"status_code": 34}"#.utf8))

        do {
            _ = try await repository.detailsBundle(for: 999_999_999)
            Issue.record("expected APIError.notFound")
        } catch APIError.notFound {
            // expected
        } catch {
            Issue.record("expected APIError.notFound, got \(error)")
        }
    }
}
