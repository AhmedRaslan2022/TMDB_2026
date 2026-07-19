//
//  FavoritesRemoteDataSource.swift
//  TMDB
//
//  Created by Ahmed Raslan on 19/07/2026.
//

import CoreModels
import Networking

/// Raw TMDB account-favorites calls. Internal: only the sync layer consumes
/// it; the protocol exists so its tests can mock the wire.
protocol FavoritesRemoteDataSource: Sendable {
    /// One page of the account's favorite movies.
    func favorites(account: FavoritesAccount, page: Int) async throws -> MoviePage
    /// Adds or removes a movie from the account's favorites.
    func setFavorite(account: FavoritesAccount, movieID: Int, isFavorite: Bool) async throws
}

struct FavoritesRemoteDataSourceImpl: FavoritesRemoteDataSource {
    let apiClient: any APIClient

    func favorites(account: FavoritesAccount, page: Int) async throws -> MoviePage {
        let dto: FavoritesPageDTO = try await apiClient.send(
            FavoritesEndpoint.list(accountID: account.accountID, sessionID: account.sessionID, page: page)
        )
        return dto.toDomain()
    }

    func setFavorite(account: FavoritesAccount, movieID: Int, isFavorite: Bool) async throws {
        try await apiClient.sendRaw(FavoritesEndpoint.setFavorite(
            accountID: account.accountID,
            sessionID: account.sessionID,
            movieID: movieID,
            isFavorite: isFavorite
        ))
    }
}
