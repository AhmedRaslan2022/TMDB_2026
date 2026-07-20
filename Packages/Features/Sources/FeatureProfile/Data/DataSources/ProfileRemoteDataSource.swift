//
//  ProfileRemoteDataSource.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

import Networking

/// Raw TMDB account calls. Internal: only the repository consumes it; the
/// protocol exists so repository tests can mock the wire (and distinguish the
/// favorite vs watchlist count calls, which a single URLProtocol stub can't).
protocol ProfileRemoteDataSource: Sendable {
    func account(sessionID: String) async throws -> AccountDTO
    func favoriteCount(accountID: Int, sessionID: String) async throws -> Int
    func watchlistCount(accountID: Int, sessionID: String) async throws -> Int
}

struct ProfileRemoteDataSourceImpl: ProfileRemoteDataSource {
    let apiClient: any APIClient

    func account(sessionID: String) async throws -> AccountDTO {
        try await apiClient.send(ProfileEndpoint.account(sessionID: sessionID))
    }

    func favoriteCount(accountID: Int, sessionID: String) async throws -> Int {
        let dto: CountDTO = try await apiClient.send(
            ProfileEndpoint.favoriteCount(accountID: accountID, sessionID: sessionID)
        )
        return dto.totalResults
    }

    func watchlistCount(accountID: Int, sessionID: String) async throws -> Int {
        let dto: CountDTO = try await apiClient.send(
            ProfileEndpoint.watchlistCount(accountID: accountID, sessionID: sessionID)
        )
        return dto.totalResults
    }
}
