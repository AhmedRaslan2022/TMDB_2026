//
//  AuthMocks.swift
//  TMDB
//
//  Created by Ahmed Raslan on 17/07/2026.
//

import Foundation
@testable import FeatureAuth

/// Failure injected by tests; `unstubbed` flags a call path the test forgot
/// to stub.
enum MockError: Error, Equatable {
    case unstubbed
    case stubbed
}

/// Mocks are `@unchecked Sendable`: tests drive them from a single task, so
/// the mutable recording state is never accessed concurrently.
final class AuthRepositoryMock: AuthRepository, @unchecked Sendable {
    var requestTokenResult: Result<RequestToken, Error> = .failure(MockError.unstubbed)
    var sessionResult: Result<AuthSession, Error> = .failure(MockError.unstubbed)
    var guestSessionResult: Result<AuthSession, Error> = .failure(MockError.unstubbed)
    var deleteSessionError: Error?

    private(set) var createRequestTokenCallCount = 0
    private(set) var createSessionApprovedTokens: [RequestToken] = []
    private(set) var createGuestSessionCallCount = 0
    private(set) var deletedSessionIDs: [String] = []

    func createRequestToken() async throws -> RequestToken {
        createRequestTokenCallCount += 1
        return try requestTokenResult.get()
    }

    func createSession(approvedToken: RequestToken) async throws -> AuthSession {
        createSessionApprovedTokens.append(approvedToken)
        return try sessionResult.get()
    }

    func createGuestSession() async throws -> AuthSession {
        createGuestSessionCallCount += 1
        return try guestSessionResult.get()
    }

    func deleteSession(sessionID: String) async throws {
        deletedSessionIDs.append(sessionID)
        if let deleteSessionError {
            throw deleteSessionError
        }
    }
}

final class SessionRepositoryMock: SessionRepository, @unchecked Sendable {
    var storedSession: AuthSession?
    var saveError: Error?
    var clearError: Error?

    private(set) var savedSessions: [AuthSession] = []
    private(set) var clearSessionCallCount = 0

    func currentSession() async throws -> AuthSession? {
        storedSession
    }

    func save(_ session: AuthSession) async throws {
        if let saveError {
            throw saveError
        }
        savedSessions.append(session)
        storedSession = session
    }

    func clearSession() async throws {
        if let clearError {
            throw clearError
        }
        clearSessionCallCount += 1
        storedSession = nil
    }
}

final class AuthRemoteDataSourceMock: AuthRemoteDataSource, @unchecked Sendable {
    var requestTokenResult: Result<RequestTokenDTO, Error> = .failure(MockError.unstubbed)
    var sessionResult: Result<CreateSessionDTO, Error> = .failure(MockError.unstubbed)
    var guestSessionResult: Result<GuestSessionDTO, Error> = .failure(MockError.unstubbed)
    var deleteSessionError: Error?

    private(set) var createSessionTokens: [String] = []
    private(set) var deletedSessionIDs: [String] = []

    func createRequestToken() async throws -> RequestTokenDTO {
        try requestTokenResult.get()
    }

    func createSession(requestToken: String) async throws -> CreateSessionDTO {
        createSessionTokens.append(requestToken)
        return try sessionResult.get()
    }

    func createGuestSession() async throws -> GuestSessionDTO {
        try guestSessionResult.get()
    }

    func deleteSession(sessionID: String) async throws {
        deletedSessionIDs.append(sessionID)
        if let deleteSessionError {
            throw deleteSessionError
        }
    }
}

final class RequestTokenAuthorizerMock: RequestTokenAuthorizer, @unchecked Sendable {
    var result: Result<RequestToken, Error> = .failure(MockError.unstubbed)

    private(set) var receivedTokens: [RequestToken] = []

    func authorize(_ token: RequestToken) async throws -> RequestToken {
        receivedTokens.append(token)
        return try result.get()
    }
}

/// `LoginUseCase` and `CreateGuestSessionUseCase` share the exact shape
/// (`execute() async throws -> AuthSession`), so one mock conforms to both;
/// tests inject two separate instances to keep the paths distinct.
@MainActor
final class AuthUseCaseMock: LoginUseCase, CreateGuestSessionUseCase {
    var result: Result<AuthSession, Error> = .failure(MockError.unstubbed)
    private(set) var executeCallCount = 0

    func execute() async throws -> AuthSession {
        executeCallCount += 1
        return try result.get()
    }
}

/// Suspends inside `execute` until the test calls `release`, so the caller's
/// intermediate `loading` state and the re-entrancy guard are observable.
@MainActor
final class GatedAuthUseCaseMock: LoginUseCase {
    var result: Result<AuthSession, Error> = .success(.authenticated(sessionID: "gated"))
    private(set) var executeCallCount = 0
    private var continuation: CheckedContinuation<Void, Never>?

    func execute() async throws -> AuthSession {
        executeCallCount += 1
        await withCheckedContinuation { continuation = $0 }
        return try result.get()
    }

    func release() {
        continuation?.resume()
        continuation = nil
    }
}
