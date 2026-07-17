//
//  CreateGuestSessionUseCase.swift
//  TMDB
//
//  Created by Ahmed Raslan on 17/07/2026.
//

/// Starts an anonymous guest session and persists it locally.
public protocol CreateGuestSessionUseCase: Sendable {
    /// - Returns: The newly created, already-persisted guest session.
    /// - Throws: Data layer errors. Nothing is persisted on failure.
    @discardableResult
    func execute() async throws -> AuthSession
}

public struct CreateGuestSessionUseCaseImpl: CreateGuestSessionUseCase {
    private let authRepository: any AuthRepository
    private let sessionRepository: any SessionRepository

    public init(
        authRepository: any AuthRepository,
        sessionRepository: any SessionRepository
    ) {
        self.authRepository = authRepository
        self.sessionRepository = sessionRepository
    }

    @discardableResult
    public func execute() async throws -> AuthSession {
        let session = try await authRepository.createGuestSession()
        try await sessionRepository.save(session)
        return session
    }
}
