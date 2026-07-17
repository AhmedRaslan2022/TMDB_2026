//
//  AuthRemoteDataSourceTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 17/07/2026.
//

import Foundation
import Networking
import SharedTestSupport
import Testing
@testable import FeatureAuth

@Suite("AuthRemoteDataSource")
struct AuthRemoteDataSourceTests {
    private let stub: URLProtocolStub.Handle
    private let dataSource: AuthRemoteDataSourceImpl

    init() throws {
        let (session, stub) = URLProtocolStub.makeSession()
        self.stub = stub
        let baseURL = try #require(URL(string: "https://stub.invalid/3"))
        dataSource = AuthRemoteDataSourceImpl(
            apiClient: URLSessionAPIClient(baseURL: baseURL, session: session)
        )
    }

    @Test("createRequestToken decodes TMDB's snake_case payload and hits the right route")
    func createRequestToken() async throws {
        stub.stub(data: Data("""
        {"success": true, "expires_at": "2026-07-18 12:00:00 UTC", "request_token": "token-1"}
        """.utf8))

        let dto = try await dataSource.createRequestToken()

        #expect(dto.requestToken == "token-1")
        #expect(dto.expiresAt == "2026-07-18 12:00:00 UTC")
        #expect(dto.success)
        let request = try #require(stub.lastRequest)
        #expect(request.url?.path() == "/3/authentication/token/new")
        #expect(request.httpMethod == "GET")
    }

    @Test("createSession decodes the session ID and POSTs to the session route")
    func createSession() async throws {
        stub.stub(data: Data(#"{"success": true, "session_id": "session-1"}"#.utf8))

        let dto = try await dataSource.createSession(requestToken: "approved")

        #expect(dto.sessionId == "session-1")
        let request = try #require(stub.lastRequest)
        #expect(request.url?.path() == "/3/authentication/session/new")
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
    }

    @Test("createGuestSession decodes the guest session ID")
    func createGuestSession() async throws {
        stub.stub(data: Data("""
        {"success": true, "guest_session_id": "guest-1", "expires_at": "2026-07-18 12:00:00 UTC"}
        """.utf8))

        let dto = try await dataSource.createGuestSession()

        #expect(dto.guestSessionId == "guest-1")
        let request = try #require(stub.lastRequest)
        #expect(request.url?.path() == "/3/authentication/guest_session/new")
    }

    @Test("deleteSession sends DELETE and succeeds on 200")
    func deleteSession() async throws {
        stub.stub(data: Data(#"{"success": true}"#.utf8))

        try await dataSource.deleteSession(sessionID: "session-1")

        let request = try #require(stub.lastRequest)
        #expect(request.url?.path() == "/3/authentication/session")
        #expect(request.httpMethod == "DELETE")
    }

    @Test("HTTP 401 surfaces as APIError.unauthorized")
    func unauthorized() async {
        stub.stub(statusCode: 401, data: Data(#"{"status_code": 7}"#.utf8))

        do {
            _ = try await dataSource.createRequestToken()
            Issue.record("expected APIError.unauthorized")
        } catch APIError.unauthorized {
            // expected
        } catch {
            Issue.record("expected APIError.unauthorized, got \(error)")
        }
    }

    @Test("malformed payload surfaces as APIError.decoding")
    func decodingFailure() async {
        stub.stub(data: Data(#"{"success": true}"#.utf8))

        do {
            _ = try await dataSource.createRequestToken()
            Issue.record("expected APIError.decoding")
        } catch APIError.decoding {
            // expected
        } catch {
            Issue.record("expected APIError.decoding, got \(error)")
        }
    }
}
