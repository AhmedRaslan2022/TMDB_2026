//
//  SessionRepositoryImpl.swift
//  TMDB
//
//  Created by Ahmed Raslan on 17/07/2026.
//

import KeychainStorage

/// `SessionRepository` backed by the keychain. The session kind is encoded by
/// which key holds a value: an authenticated session lives under `.sessionID`,
/// a guest session under `.guestSessionID`. At most one is ever present —
/// saving one clears the other — so `currentSession()` is unambiguous.
public struct SessionRepositoryImpl: SessionRepository {
    private let secureStorage: any SecureStorage

    public init(secureStorage: any SecureStorage) {
        self.secureStorage = secureStorage
    }

    public func currentSession() async throws -> AuthSession? {
        if let sessionID = try await secureStorage.string(for: .sessionID) {
            return .authenticated(sessionID: sessionID)
        }
        if let guestSessionID = try await secureStorage.string(for: .guestSessionID) {
            return .guest(sessionID: guestSessionID)
        }
        return nil
    }

    public func save(_ session: AuthSession) async throws {
        switch session {
        case let .authenticated(sessionID):
            try await secureStorage.set(sessionID, for: .sessionID)
            try await secureStorage.removeValue(for: .guestSessionID)
        case let .guest(sessionID):
            try await secureStorage.set(sessionID, for: .guestSessionID)
            try await secureStorage.removeValue(for: .sessionID)
        }
    }

    public func clearSession() async throws {
        // Wipes every credential this store owns (session, guest, account id),
        // so logout leaves nothing behind for the next launch to restore.
        try await secureStorage.removeAll()
    }
}
