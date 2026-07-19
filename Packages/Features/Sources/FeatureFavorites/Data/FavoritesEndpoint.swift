//
//  FavoritesEndpoint.swift
//  TMDB
//
//  Created by Ahmed Raslan on 19/07/2026.
//

import Foundation
import Networking

/// TMDB account-favorites endpoints. Both are session-scoped (the v3 account
/// endpoints take `session_id` even though the client sends a v4 bearer).
enum FavoritesEndpoint: Endpoint {
    /// One page of the account's favorite movies.
    case list(accountID: Int, sessionID: String, page: Int)
    /// Adds or removes a movie from the account's favorites.
    case setFavorite(accountID: Int, sessionID: String, movieID: Int, isFavorite: Bool)

    var path: String {
        switch self {
        case let .list(accountID, _, _): "/account/\(accountID)/favorite/movies"
        case let .setFavorite(accountID, _, _, _): "/account/\(accountID)/favorite"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .list: .get
        case .setFavorite: .post
        }
    }

    var queryItems: [URLQueryItem] {
        switch self {
        case let .list(_, sessionID, page):
            [
                URLQueryItem(name: "session_id", value: sessionID),
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "sort_by", value: "created_at.desc"),
            ]
        case let .setFavorite(_, sessionID, _, _):
            [URLQueryItem(name: "session_id", value: sessionID)]
        }
    }

    var body: Data? {
        switch self {
        case .list:
            nil
        case let .setFavorite(_, _, movieID, isFavorite):
            try? JSONEncoder().encode(FavoriteRequestBody(
                mediaType: "movie",
                mediaId: movieID,
                favorite: isFavorite
            ))
        }
    }
}

/// POST body for the favorite toggle. Encoded to snake_case explicitly since
/// the shared client only configures snake_case *decoding*.
private struct FavoriteRequestBody: Encodable {
    let mediaType: String
    let mediaId: Int
    let favorite: Bool

    enum CodingKeys: String, CodingKey {
        case mediaType = "media_type"
        case mediaId = "media_id"
        case favorite
    }
}
