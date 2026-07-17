//
//  LogoutUseCase.swift
//  TMDB
//
//  Created by Ahmed Raslan on 17/07/2026.
//

/// Ends the current session: wipes local persistence first, then invalidates
/// authenticated sessions on TMDB's side.
///
/// Local state is cleared before the network call so the user is always
/// logged out on-device, even if the remote delete fails; that failure still
/// propagates so callers can log it. Guest sessions have no remote delete —
/// TMDB expires them by inactivity. User-scoped SwiftData wipe joins in
/// task 2.6.
public protocol LogoutUseCase: Sendable {
    func execute() async throws
}

public struct LogoutUseCaseImpl: LogoutUseCase {
    private let authRepository: any AuthRepository
    private let sessionRepository: any SessionRepository

    public init(
        authRepository: any AuthRepository,
        sessionRepository: any SessionRepository
    ) {
        self.authRepository = authRepository
        self.sessionRepository = sessionRepository
    }

    public func execute() async throws {
        let session = try await sessionRepository.currentSession()
        try await sessionRepository.clearSession()
        if case let .authenticated(sessionID) = session {
            try await authRepository.deleteSession(sessionID: sessionID)
        }
    }
}
