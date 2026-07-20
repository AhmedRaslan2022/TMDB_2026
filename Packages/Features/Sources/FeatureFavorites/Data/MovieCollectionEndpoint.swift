//
//  MovieCollectionEndpoint.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

import Foundation
import Networking

/// TMDB account collection endpoints, parameterized by `MovieCollection` so
/// favorites and watchlist share one endpoint definition. Session-scoped (the
/// v3 account endpoints take `session_id` even under a v4 bearer).
enum MovieCollectionEndpoint: Endpoint {
    /// One page of the account's collection.
    case list(collection: MovieCollection, accountID: Int, sessionID: String, page: Int)
    /// Adds or removes a movie from the account's collection.
    case setMembership(collection: MovieCollection, accountID: Int, sessionID: String, movieID: Int, isMember: Bool)

    private var collection: MovieCollection {
        switch self {
        case let .list(collection, _, _, _), let .setMembership(collection, _, _, _, _): collection
        }
    }

    var path: String {
        switch self {
        case let .list(collection, accountID, _, _):
            "/account/\(accountID)/\(collection.remoteSegment)/movies"
        case let .setMembership(collection, accountID, _, _, _):
            "/account/\(accountID)/\(collection.remoteSegment)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .list: .get
        case .setMembership: .post
        }
    }

    var queryItems: [URLQueryItem] {
        switch self {
        case let .list(_, _, sessionID, page):
            [
                URLQueryItem(name: "session_id", value: sessionID),
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "sort_by", value: "created_at.desc"),
            ]
        case let .setMembership(_, _, sessionID, _, _):
            [URLQueryItem(name: "session_id", value: sessionID)]
        }
    }

    var body: Data? {
        // Only the toggle carries a body. Snake_case encoded explicitly since
        // the shared client configures snake_case *decoding* only; the
        // membership key differs per collection ("favorite" vs "watchlist").
        guard case let .setMembership(collection, _, _, movieID, isMember) = self else { return nil }
        var json: [String: Any] = ["media_type": "movie", "media_id": movieID]
        json[collection.bodyKey] = isMember
        return try? JSONSerialization.data(withJSONObject: json)
    }
}
