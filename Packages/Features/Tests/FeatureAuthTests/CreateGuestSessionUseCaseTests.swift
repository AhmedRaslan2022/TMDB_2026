//
//  CreateGuestSessionUseCaseTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 17/07/2026.
//

import Testing
@testable import FeatureAuth

@Suite("CreateGuestSessionUseCase")
struct CreateGuestSessionUseCaseTests {
    private let authRepository = AuthRepositoryMock()
    private let sessionRepository = SessionRepositoryMock()
    private let useCase: CreateGuestSessionUseCaseImpl

    init() {
        useCase = CreateGuestSessionUseCaseImpl(
            authRepository: authRepository,
            sessionRepository: sessionRepository
        )
    }

    @Test("creates a guest session, persists it and returns it")
    func happyPath() async throws {
        authRepository.guestSessionResult = .success(.guest(sessionID: "guest-1"))

        let session = try await useCase.execute()

        #expect(session == .guest(sessionID: "guest-1"))
        #expect(authRepository.createGuestSessionCallCount == 1)
        #expect(sessionRepository.savedSessions == [.guest(sessionID: "guest-1")])
    }

    @Test("creation failure propagates; nothing is saved")
    func creationFails() async {
        authRepository.guestSessionResult = .failure(MockError.stubbed)

        await #expect(throws: MockError.stubbed) {
            try await useCase.execute()
        }
        #expect(sessionRepository.savedSessions.isEmpty)
    }

    @Test("persistence failure propagates to the caller")
    func saveFails() async {
        authRepository.guestSessionResult = .success(.guest(sessionID: "guest-1"))
        sessionRepository.saveError = MockError.stubbed

        await #expect(throws: MockError.stubbed) {
            try await useCase.execute()
        }
    }
}
