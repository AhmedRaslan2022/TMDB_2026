//
//  AuthRepositoryImplTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 17/07/2026.
//

import Foundation
import Networking
import Testing
@testable import FeatureAuth

@Suite("AuthRepositoryImpl")
struct AuthRepositoryImplTests {
    private let dataSource = AuthRemoteDataSourceMock()
    private let repository: AuthRepositoryImpl

    init() {
        repository = AuthRepositoryImpl(dataSource: dataSource)
    }

    @Test("createRequestToken maps the DTO, parsing TMDB's UTC expiry format")
    func requestTokenMapping() async throws {
        dataSource.requestTokenResult = .success(
            RequestTokenDTO(success: true, expiresAt: "2026-07-18 12:00:00 UTC", requestToken: "token-1")
        )

        let token = try await repository.createRequestToken()

        #expect(token.value == "token-1")
        var components = DateComponents(year: 2026, month: 7, day: 18, hour: 12)
        components.timeZone = TimeZone(identifier: "UTC")
        #expect(token.expiresAt == Calendar(identifier: .gregorian).date(from: components))
    }

    @Test("an unparseable expiry surfaces as AuthDataError.invalidExpiryDate")
    func invalidExpiryDate() async {
        dataSource.requestTokenResult = .success(
            RequestTokenDTO(success: true, expiresAt: "tomorrow-ish", requestToken: "token-1")
        )

        await #expect(throws: AuthDataError.invalidExpiryDate("tomorrow-ish")) {
            try await repository.createRequestToken()
        }
    }

    @Test("createSession maps to an authenticated session and forwards the token value")
    func createSessionMapping() async throws {
        dataSource.sessionResult = .success(CreateSessionDTO(success: true, sessionId: "session-1"))

        let session = try await repository.createSession(
            approvedToken: RequestToken(value: "approved", expiresAt: .distantFuture)
        )

        #expect(session == .authenticated(sessionID: "session-1"))
        #expect(dataSource.createSessionTokens == ["approved"])
    }

    @Test("a 401 on session creation becomes AuthError.tokenNotApproved")
    func unapprovedToken() async {
        dataSource.sessionResult = .failure(APIError.unauthorized)

        await #expect(throws: AuthError.tokenNotApproved) {
            try await repository.createSession(
                approvedToken: RequestToken(value: "unapproved", expiresAt: .distantFuture)
            )
        }
    }

    @Test("non-401 session creation errors pass through untranslated")
    func otherSessionErrorsPassThrough() async {
        dataSource.sessionResult = .failure(APIError.server(statusCode: 500))

        do {
            _ = try await repository.createSession(
                approvedToken: RequestToken(value: "approved", expiresAt: .distantFuture)
            )
            Issue.record("expected APIError.server")
        } catch APIError.server(statusCode: 500) {
            // expected
        } catch {
            Issue.record("expected APIError.server, got \(error)")
        }
    }

    @Test("createGuestSession maps to a guest session")
    func guestSessionMapping() async throws {
        dataSource.guestSessionResult = .success(
            GuestSessionDTO(success: true, guestSessionId: "guest-1", expiresAt: "2026-07-18 12:00:00 UTC")
        )

        let session = try await repository.createGuestSession()

        #expect(session == .guest(sessionID: "guest-1"))
    }

    @Test("deleteSession forwards the session ID")
    func deleteSessionForwardsID() async throws {
        try await repository.deleteSession(sessionID: "session-1")

        #expect(dataSource.deletedSessionIDs == ["session-1"])
    }

    @Test("deleteSession errors pass through untranslated")
    func deleteSessionErrorPassesThrough() async {
        dataSource.deleteSessionError = MockError.stubbed

        await #expect(throws: MockError.stubbed) {
            try await repository.deleteSession(sessionID: "session-1")
        }
    }
}
