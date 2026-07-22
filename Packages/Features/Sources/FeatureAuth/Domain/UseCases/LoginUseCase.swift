//
//  LoginUseCase.swift
//  TMDB
//
//  Created by Ahmed Raslan on 17/07/2026.
//

/// Logs the user in with their TMDB account: request token → user approval on
/// TMDB's site → session creation → local persistence.
public protocol LoginUseCase: Sendable {
    /// - Returns: The newly created, already-persisted session.
    /// - Throws: `AuthError.userCancelled` when approval is dismissed; data
    ///   layer errors otherwise. Nothing is persisted on failure.
    @discardableResult
    func execute() async throws -> AuthSession
}

public struct LoginUseCaseImpl: LoginUseCase {
    private let authRepository: any AuthRepository
    private let sessionRepository: any SessionRepository
    private let authorizer: any RequestTokenAuthorizer

    public init(
        authRepository: any AuthRepository,
        sessionRepository: any SessionRepository,
        authorizer: any RequestTokenAuthorizer
    ) {
        self.authRepository = authRepository
        self.sessionRepository = sessionRepository
        self.authorizer = authorizer
    }

    @discardableResult
    public func execute() async throws -> AuthSession {
        let token = try await authRepository.createRequestToken()
        let approvedToken = try await authorizer.authorize(token)
        let session = try await authRepository.createSession(approvedToken: approvedToken)
        try await sessionRepository.save(session)
        return session
    }
}
