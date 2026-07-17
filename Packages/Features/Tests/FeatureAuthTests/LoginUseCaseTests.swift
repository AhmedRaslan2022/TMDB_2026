//
//  LoginUseCaseTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 17/07/2026.
//

import Foundation
import Testing
@testable import FeatureAuth

@Suite("LoginUseCase")
struct LoginUseCaseTests {
    private let authRepository = AuthRepositoryMock()
    private let sessionRepository = SessionRepositoryMock()
    private let authorizer = RequestTokenAuthorizerMock()
    private let useCase: LoginUseCaseImpl

    private let issuedToken = RequestToken(value: "issued", expiresAt: .distantFuture)
    private let approvedToken = RequestToken(value: "approved", expiresAt: .distantFuture)

    init() {
        useCase = LoginUseCaseImpl(
            authRepository: authRepository,
            sessionRepository: sessionRepository,
            authorizer: authorizer
        )
    }

    @Test("happy path: token → approval → session, session persisted and returned")
    func happyPath() async throws {
        authRepository.requestTokenResult = .success(issuedToken)
        authorizer.result = .success(approvedToken)
        authRepository.sessionResult = .success(.authenticated(sessionID: "session-1"))

        let session = try await useCase.execute()

        #expect(session == .authenticated(sessionID: "session-1"))
        #expect(authorizer.receivedTokens == [issuedToken])
        #expect(authRepository.createSessionApprovedTokens == [approvedToken])
        #expect(sessionRepository.savedSessions == [.authenticated(sessionID: "session-1")])
    }

    @Test("user cancelling approval propagates userCancelled; no session is created or saved")
    func userCancelled() async {
        authRepository.requestTokenResult = .success(issuedToken)
        authorizer.result = .failure(AuthError.userCancelled)

        await #expect(throws: AuthError.userCancelled) {
            try await useCase.execute()
        }
        #expect(authRepository.createSessionApprovedTokens.isEmpty)
        #expect(sessionRepository.savedSessions.isEmpty)
    }

    @Test("token creation failure propagates; the approval page is never shown")
    func tokenCreationFails() async {
        authRepository.requestTokenResult = .failure(MockError.stubbed)

        await #expect(throws: MockError.stubbed) {
            try await useCase.execute()
        }
        #expect(authorizer.receivedTokens.isEmpty)
        #expect(sessionRepository.savedSessions.isEmpty)
    }

    @Test("session creation failure propagates; nothing is saved")
    func sessionCreationFails() async {
        authRepository.requestTokenResult = .success(issuedToken)
        authorizer.result = .success(approvedToken)
        authRepository.sessionResult = .failure(MockError.stubbed)

        await #expect(throws: MockError.stubbed) {
            try await useCase.execute()
        }
        #expect(sessionRepository.savedSessions.isEmpty)
    }

    @Test("persistence failure propagates to the caller")
    func saveFails() async {
        authRepository.requestTokenResult = .success(issuedToken)
        authorizer.result = .success(approvedToken)
        authRepository.sessionResult = .success(.authenticated(sessionID: "session-1"))
        sessionRepository.saveError = MockError.stubbed

        await #expect(throws: MockError.stubbed) {
            try await useCase.execute()
        }
    }
}
