//
//  MovieCollectionRemoteDataSource.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

import CoreModels
import Networking

/// Raw TMDB account-collection calls, parameterized by `MovieCollection`.
/// Internal: only the store consumes it; the protocol exists so its tests can
/// mock the wire.
protocol MovieCollectionRemoteDataSource: Sendable {
    func list(collection: MovieCollection, account: FavoritesAccount, page: Int) async throws -> MoviePage
    func setMembership(
        collection: MovieCollection,
        account: FavoritesAccount,
        movieID: Int,
        isMember: Bool
    ) async throws
}

struct MovieCollectionRemoteDataSourceImpl: MovieCollectionRemoteDataSource {
    let apiClient: any APIClient

    func list(collection: MovieCollection, account: FavoritesAccount, page: Int) async throws -> MoviePage {
        let dto: FavoritesPageDTO = try await apiClient.send(MovieCollectionEndpoint.list(
            collection: collection,
            accountID: account.accountID,
            sessionID: account.sessionID,
            page: page
        ))
        return dto.toDomain()
    }

    func setMembership(
        collection: MovieCollection,
        account: FavoritesAccount,
        movieID: Int,
        isMember: Bool
    ) async throws {
        try await apiClient.sendRaw(MovieCollectionEndpoint.setMembership(
            collection: collection,
            accountID: account.accountID,
            sessionID: account.sessionID,
            movieID: movieID,
            isMember: isMember
        ))
    }
}
