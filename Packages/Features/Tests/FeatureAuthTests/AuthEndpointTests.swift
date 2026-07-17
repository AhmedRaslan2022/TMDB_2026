//
//  AuthEndpointTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 17/07/2026.
//

import Foundation
import Testing
@testable import FeatureAuth

@Suite("AuthEndpoint")
struct AuthEndpointTests {
    @Test("paths match TMDB v3 authentication routes")
    func paths() {
        #expect(AuthEndpoint.createRequestToken.path == "/authentication/token/new")
        #expect(AuthEndpoint.createSession(requestToken: "t").path == "/authentication/session/new")
        #expect(AuthEndpoint.createGuestSession.path == "/authentication/guest_session/new")
        #expect(AuthEndpoint.deleteSession(sessionID: "s").path == "/authentication/session")
    }

    @Test("methods: token/guest are GET, session create is POST, delete is DELETE")
    func methods() {
        #expect(AuthEndpoint.createRequestToken.method == .get)
        #expect(AuthEndpoint.createSession(requestToken: "t").method == .post)
        #expect(AuthEndpoint.createGuestSession.method == .get)
        #expect(AuthEndpoint.deleteSession(sessionID: "s").method == .delete)
    }

    @Test("createSession body carries the request token as snake_case JSON")
    func createSessionBody() throws {
        let body = try #require(AuthEndpoint.createSession(requestToken: "approved-token").body)
        let json = try JSONDecoder().decode([String: String].self, from: body)
        #expect(json == ["request_token": "approved-token"])
    }

    @Test("deleteSession body carries the session ID as snake_case JSON")
    func deleteSessionBody() throws {
        let body = try #require(AuthEndpoint.deleteSession(sessionID: "session-1").body)
        let json = try JSONDecoder().decode([String: String].self, from: body)
        #expect(json == ["session_id": "session-1"])
    }

    @Test("GET endpoints have no body")
    func getEndpointsHaveNoBody() {
        #expect(AuthEndpoint.createRequestToken.body == nil)
        #expect(AuthEndpoint.createGuestSession.body == nil)
    }
}
