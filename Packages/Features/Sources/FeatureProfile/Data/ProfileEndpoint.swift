//
//  ProfileEndpoint.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

import Foundation
import Networking

/// TMDB v3 account endpoints. Session-scoped (they take `session_id`). The
/// count endpoints are the favorites/watchlist lists — only `total_results`
/// is read, so page 1 suffices.
enum ProfileEndpoint: Endpoint {
    case account(sessionID: String)
    case favoriteCount(accountID: Int, sessionID: String)
    case watchlistCount(accountID: Int, sessionID: String)

    var path: String {
        switch self {
        case .account: "/account"
        case let .favoriteCount(accountID, _): "/account/\(accountID)/favorite/movies"
        case let .watchlistCount(accountID, _): "/account/\(accountID)/watchlist/movies"
        }
    }

    var queryItems: [URLQueryItem] {
        switch self {
        case let .account(sessionID):
            [URLQueryItem(name: "session_id", value: sessionID)]
        case let .favoriteCount(_, sessionID), let .watchlistCount(_, sessionID):
            [
                URLQueryItem(name: "session_id", value: sessionID),
                URLQueryItem(name: "page", value: "1"),
            ]
        }
    }
}
