//
//  MovieRatingEndpointTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

import Foundation
import Networking
import Testing
@testable import FeatureMovieDetails

@Suite("MovieRatingEndpoint")
struct MovieRatingEndpointTests {
    @Test("account states: GET with the session query, no body")
    func accountStates() {
        let endpoint = MovieRatingEndpoint.accountStates(movieID: 550, sessionID: "sess")

        #expect(endpoint.path == "/movie/550/account_states")
        #expect(endpoint.method == .get)
        #expect(endpoint.queryItems == [URLQueryItem(name: "session_id", value: "sess")])
        #expect(endpoint.body == nil)
    }

    @Test("rate: POST /rating with the value body")
    func rate() throws {
        let endpoint = MovieRatingEndpoint.rate(movieID: 550, value: 8, sessionID: "sess")

        #expect(endpoint.path == "/movie/550/rating")
        #expect(endpoint.method == .post)
        #expect(endpoint.queryItems == [URLQueryItem(name: "session_id", value: "sess")])
        let body = try #require(endpoint.body)
        let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(json["value"] as? Double == 8)
    }

    @Test("delete: DELETE /rating with the session query, no body")
    func delete() {
        let endpoint = MovieRatingEndpoint.delete(movieID: 550, sessionID: "sess")

        #expect(endpoint.path == "/movie/550/rating")
        #expect(endpoint.method == .delete)
        #expect(endpoint.queryItems == [URLQueryItem(name: "session_id", value: "sess")])
        #expect(endpoint.body == nil)
    }

    @Test("rating values snap onto TMDB's 0.5–10 grid", arguments: [
        (7.3, 7.5),
        (7.1, 7.0),
        (0.0, 0.5),
        (-2.0, 0.5),
        (20.0, 10.0),
        (8.0, 8.0),
    ])
    func normalization(input: Double, expected: Double) throws {
        let endpoint = MovieRatingEndpoint.rate(movieID: 1, value: input, sessionID: "s")
        let body = try #require(endpoint.body)
        let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(json["value"] as? Double == expected)
    }
}
