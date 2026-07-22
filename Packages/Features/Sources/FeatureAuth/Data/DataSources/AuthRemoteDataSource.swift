//
//  AuthRemoteDataSource.swift
//  TMDB
//
//  Created by Ahmed Raslan on 17/07/2026.
//

import Networking

/// Raw TMDB auth calls, returning DTOs. Internal: only `AuthRepositoryImpl`
/// consumes it; the protocol exists so repository tests can mock the wire.
protocol AuthRemoteDataSource: Sendable {
    func createRequestToken() async throws -> RequestTokenDTO
    func createSession(requestToken: String) async throws -> CreateSessionDTO
    func createGuestSession() async throws -> GuestSessionDTO
    func deleteSession(sessionID: String) async throws
}

struct AuthRemoteDataSourceImpl: AuthRemoteDataSource {
    let apiClient: any APIClient

    func createRequestToken() async throws -> RequestTokenDTO {
        try await apiClient.send(AuthEndpoint.createRequestToken)
    }

    func createSession(requestToken: String) async throws -> CreateSessionDTO {
        try await apiClient.send(AuthEndpoint.createSession(requestToken: requestToken))
    }

    func createGuestSession() async throws -> GuestSessionDTO {
        try await apiClient.send(AuthEndpoint.createGuestSession)
    }

    func deleteSession(sessionID: String) async throws {
        try await apiClient.sendRaw(AuthEndpoint.deleteSession(sessionID: sessionID))
    }
}
