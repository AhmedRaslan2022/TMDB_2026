//
//  AuthRepositoryImpl.swift
//  TMDB
//
//  Created by Ahmed Raslan on 17/07/2026.
//

import Networking

/// `AuthRepository` over the TMDB API. Maps DTOs to Domain entities at the
/// boundary; DTOs never leave this layer.
public struct AuthRepositoryImpl: AuthRepository {
    private let dataSource: any AuthRemoteDataSource

    /// Composition-root entry point: wires the internal data source.
    public init(apiClient: any APIClient) {
        self.init(dataSource: AuthRemoteDataSourceImpl(apiClient: apiClient))
    }

    init(dataSource: any AuthRemoteDataSource) {
        self.dataSource = dataSource
    }

    public func createRequestToken() async throws -> RequestToken {
        try await dataSource.createRequestToken().toDomain()
    }

    public func createSession(approvedToken: RequestToken) async throws -> AuthSession {
        do {
            return try await dataSource.createSession(requestToken: approvedToken.value).toDomain()
        } catch APIError.unauthorized {
            // TMDB answers 401 when the token was never approved; surface it
            // as the domain outcome so presentation can explain it.
            throw AuthError.tokenNotApproved
        }
    }

    public func createGuestSession() async throws -> AuthSession {
        try await dataSource.createGuestSession().toDomain()
    }

    public func deleteSession(sessionID: String) async throws {
        try await dataSource.deleteSession(sessionID: sessionID)
    }
}
