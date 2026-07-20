//
//  ProfileRepositoryImpl.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

import KeychainStorage
import Networking

/// `ProfileRepository` over the TMDB API. Reads the authenticated session
/// from the keychain and — after fetching the account — caches its id under
/// `.accountID`, which is what activates favorites/watchlist remote sync
/// (previously inert because the id was unknown).
public struct ProfileRepositoryImpl: ProfileRepository {
    private let dataSource: any ProfileRemoteDataSource
    private let secureStorage: any SecureStorage

    /// Composition-root entry point: wires the internal data source.
    public init(apiClient: any APIClient, secureStorage: any SecureStorage) {
        self.init(dataSource: ProfileRemoteDataSourceImpl(apiClient: apiClient), secureStorage: secureStorage)
    }

    init(dataSource: any ProfileRemoteDataSource, secureStorage: any SecureStorage) {
        self.dataSource = dataSource
        self.secureStorage = secureStorage
    }

    public func account() async throws -> Account {
        let sessionID = try await authenticatedSessionID()
        let account = try await dataSource.account(sessionID: sessionID).toDomain()
        // Cache the id so favorites/watchlist sync can resolve the account.
        try await secureStorage.set(String(account.id), for: .accountID)
        return account
    }

    public func stats(for accountID: Int) async throws -> AccountStats {
        let sessionID = try await authenticatedSessionID()
        async let favorites = dataSource.favoriteCount(accountID: accountID, sessionID: sessionID)
        async let watchlist = dataSource.watchlistCount(accountID: accountID, sessionID: sessionID)
        return try await AccountStats(favoriteCount: favorites, watchlistCount: watchlist)
    }

    /// The authenticated session id, or `ProfileError.notAuthenticated` for a
    /// guest / logged-out user (who has no account).
    private func authenticatedSessionID() async throws -> String {
        guard let sessionID = try await secureStorage.string(for: .sessionID) else {
            throw ProfileError.notAuthenticated
        }
        return sessionID
    }
}
