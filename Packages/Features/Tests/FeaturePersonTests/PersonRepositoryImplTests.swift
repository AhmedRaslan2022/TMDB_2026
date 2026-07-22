//
//  PersonRepositoryImplTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 21/07/2026.
//

import CoreModels
import Foundation
import Networking
import SharedTestSupport
import Testing
@testable import FeaturePerson

/// Person repository through the real client against a stubbed `URLProtocol`:
/// routing, appended-payload decoding, and combined-credits → MediaItem mapping.
@Suite("PersonRepositoryImpl")
struct PersonRepositoryImplTests {
    private let stub: URLProtocolStub.Handle
    private let repository: PersonRepositoryImpl

    init() throws {
        let (session, stub) = URLProtocolStub.makeSession()
        self.stub = stub
        let baseURL = try #require(URL(string: "https://stub.invalid/3"))
        repository = PersonRepositoryImpl(apiClient: URLSessionAPIClient(baseURL: baseURL, session: session))
    }

    private static let payload = """
    {
        "id": 287,
        "name": "Brad Pitt",
        "biography": "William Bradley Pitt is an American actor…",
        "birthday": "1963-12-18",
        "place_of_birth": "Shawnee, Oklahoma, USA",
        "profile_path": "/pitt.jpg",
        "known_for_department": "Acting",
        "combined_credits": {
            "cast": [
                {"id": 550, "media_type": "movie", "title": "Fight Club", "character": "Tyler Durden",
                 "poster_path": "/fc.jpg", "release_date": "1999-10-15", "vote_average": 8.4, "vote_count": 30000},
                {"id": 87739, "media_type": "tv", "name": "The Big Short Series", "character": "Self",
                 "first_air_date": "2015-01-01", "vote_average": 7.0, "vote_count": 500},
                {"id": 999, "media_type": "person", "name": "Not A Title"}
            ]
        },
        "images": {"profiles": [{"file_path": "/img1.jpg"}, {"file_path": "/img2.jpg"}]}
    }
    """

    @Test("decodes the person, hitting the right route with combined credits + images")
    func decodesPerson() async throws {
        stub.stub(data: Data(Self.payload.utf8))

        let bundle = try await repository.detailsBundle(for: 287)

        #expect(bundle.person.id == 287)
        #expect(bundle.person.name == "Brad Pitt")
        #expect(bundle.person.knownForDepartment == "Acting")
        #expect(bundle.person.placeOfBirth == "Shawnee, Oklahoma, USA")
        var comps = DateComponents(year: 1963, month: 12, day: 18)
        comps.timeZone = TimeZone(identifier: "UTC")
        #expect(bundle.person.birthday == Calendar(identifier: .gregorian).date(from: comps))
        #expect(bundle.imagePaths == ["/img1.jpg", "/img2.jpg"])

        let url = try #require(stub.lastRequest?.url)
        #expect(url.path() == "/3/person/287")
        let comps2 = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        #expect(comps2.queryItems == [URLQueryItem(name: "append_to_response", value: "combined_credits,images")])
    }

    @Test("filmography maps mixed movie/TV credits to MediaItem, dropping non-title credits")
    func filmographyMapping() async throws {
        stub.stub(data: Data(Self.payload.utf8))

        let bundle = try await repository.detailsBundle(for: 287)

        // "person" media_type is dropped; movie + tv remain, sorted by votes.
        #expect(bundle.filmography.map(\.media.id) == [550, 87739])
        let fightClub = try #require(bundle.filmography.first)
        #expect(fightClub.media.mediaType == .movie)
        #expect(fightClub.media.title == "Fight Club")
        #expect(fightClub.character == "Tyler Durden")
        let tvCredit = bundle.filmography[1]
        #expect(tvCredit.media.mediaType == .tv)
        #expect(tvCredit.media.title == "The Big Short Series", "TV credit uses name as the shared title")
    }

    @Test("a bare payload maps to a person with empty filmography and images")
    func barePayload() async throws {
        stub.stub(data: Data(#"{"id": 1, "name": "Nobody"}"#.utf8))

        let bundle = try await repository.detailsBundle(for: 1)

        #expect(bundle.person.name == "Nobody")
        #expect(bundle.person.biography.isEmpty)
        #expect(bundle.filmography.isEmpty)
        #expect(bundle.imagePaths.isEmpty)
    }

    @Test("the use case delegates to the repository")
    func useCaseDelegates() async throws {
        stub.stub(data: Data(#"{"id": 5, "name": "X"}"#.utf8))
        let useCase = FetchPersonDetailsUseCaseImpl(repository: repository)

        let bundle = try await useCase.execute(personID: 5)

        #expect(bundle.person.id == 5)
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
