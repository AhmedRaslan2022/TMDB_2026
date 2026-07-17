//
//  LogoutUseCaseTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 17/07/2026.
//

import Testing
@testable import FeatureAuth

@Suite("LogoutUseCase")
struct LogoutUseCaseTests {
    private let authRepository = AuthRepositoryMock()
    private let sessionRepository = SessionRepositoryMock()
    private let useCase: LogoutUseCaseImpl

    init() {
        useCase = LogoutUseCaseImpl(
            authRepository: authRepository,
            sessionRepository: sessionRepository
        )
    }

    @Test("authenticated session: local state cleared and remote session deleted")
    func authenticatedLogout() async throws {
        sessionRepository.storedSession = .authenticated(sessionID: "session-1")

        try await useCase.execute()

        #expect(sessionRepository.clearSessionCallCount == 1)
        #expect(sessionRepository.storedSession == nil)
        #expect(authRepository.deletedSessionIDs == ["session-1"])
    }

    @Test("guest session: local state cleared, no remote delete — TMDB expires guests")
    func guestLogout() async throws {
        sessionRepository.storedSession = .guest(sessionID: "guest-1")

        try await useCase.execute()

        #expect(sessionRepository.clearSessionCallCount == 1)
        #expect(authRepository.deletedSessionIDs.isEmpty)
    }

    @Test("no stored session: clearing is a no-op success without remote calls")
    func loggedOutAlready() async throws {
        try await useCase.execute()

        #expect(sessionRepository.clearSessionCallCount == 1)
        #expect(authRepository.deletedSessionIDs.isEmpty)
    }

    @Test("remote delete failure still leaves the device logged out, then propagates")
    func remoteDeleteFails() async {
        sessionRepository.storedSession = .authenticated(sessionID: "session-1")
        authRepository.deleteSessionError = MockError.stubbed

        await #expect(throws: MockError.stubbed) {
            try await useCase.execute()
        }
        #expect(sessionRepository.clearSessionCallCount == 1)
        #expect(sessionRepository.storedSession == nil)
    }
}
