//
//  SessionRepositoryImplTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 17/07/2026.
//

import KeychainStorage
import Testing
@testable import FeatureAuth

@Suite("SessionRepositoryImpl")
struct SessionRepositoryImplTests {
    private let storage = InMemorySecureStorage()
    private let repository: SessionRepositoryImpl

    init() {
        repository = SessionRepositoryImpl(secureStorage: storage)
    }

    @Test("no stored session reads back as nil")
    func emptyIsNil() async throws {
        #expect(try await repository.currentSession() == nil)
    }

    @Test("an authenticated session survives a save/read roundtrip")
    func authenticatedRoundtrip() async throws {
        try await repository.save(.authenticated(sessionID: "session-1"))

        #expect(try await repository.currentSession() == .authenticated(sessionID: "session-1"))
    }

    @Test("a guest session survives a save/read roundtrip")
    func guestRoundtrip() async throws {
        try await repository.save(.guest(sessionID: "guest-1"))

        #expect(try await repository.currentSession() == .guest(sessionID: "guest-1"))
    }

    @Test("saving an authenticated session clears a prior guest session")
    func authenticatedReplacesGuest() async throws {
        try await repository.save(.guest(sessionID: "guest-1"))
        try await repository.save(.authenticated(sessionID: "session-1"))

        #expect(try await repository.currentSession() == .authenticated(sessionID: "session-1"))
        #expect(try await storage.string(for: .guestSessionID) == nil)
    }

    @Test("saving a guest session clears a prior authenticated session")
    func guestReplacesAuthenticated() async throws {
        try await repository.save(.authenticated(sessionID: "session-1"))
        try await repository.save(.guest(sessionID: "guest-1"))

        #expect(try await repository.currentSession() == .guest(sessionID: "guest-1"))
        #expect(try await storage.string(for: .sessionID) == nil)
    }

    @Test("an authenticated session takes precedence if both keys are somehow present")
    func authenticatedPrecedence() async throws {
        await storage.seed("session-1", for: .sessionID)
        await storage.seed("guest-1", for: .guestSessionID)

        #expect(try await repository.currentSession() == .authenticated(sessionID: "session-1"))
    }

    @Test("clearSession wipes the stored session")
    func clearSession() async throws {
        try await repository.save(.authenticated(sessionID: "session-1"))

        try await repository.clearSession()

        #expect(try await repository.currentSession() == nil)
    }

    @Test("storage failures propagate to the caller")
    func failurePropagates() async throws {
        await storage.setFailure(MockError.stubbed)

        await #expect(throws: MockError.stubbed) {
            try await repository.save(.authenticated(sessionID: "session-1"))
        }
    }
}
