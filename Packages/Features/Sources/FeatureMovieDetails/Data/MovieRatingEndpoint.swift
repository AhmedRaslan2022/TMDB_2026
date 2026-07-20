//
//  MovieRatingEndpoint.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

import Foundation
import Networking

/// TMDB's per-movie rating endpoints. Session scoped (the v3 rating routes take
/// `session_id` even under a v4 bearer).
enum MovieRatingEndpoint: Endpoint {
    /// The signed-in user's account state for a movie, including their rating.
    case accountStates(movieID: Int, sessionID: String)
    /// Sets the user's rating for a movie (value clamped to TMDB's 0.5–10 range).
    case rate(movieID: Int, value: Double, sessionID: String)
    /// Removes the user's rating for a movie.
    case delete(movieID: Int, sessionID: String)

    var path: String {
        switch self {
        case let .accountStates(movieID, _):
            "/movie/\(movieID)/account_states"
        case let .rate(movieID, _, _), let .delete(movieID, _):
            "/movie/\(movieID)/rating"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .accountStates: .get
        case .rate: .post
        case .delete: .delete
        }
    }

    var queryItems: [URLQueryItem] {
        [URLQueryItem(name: "session_id", value: sessionID)]
    }

    var body: Data? {
        // Only the write carries a body. Snake_case is moot here (single key),
        // and the value is normalized to a TMDB-valid step so the API never
        // rejects it. Encoded explicitly since the shared client only decodes.
        guard case let .rate(_, value, _) = self else { return nil }
        return try? JSONSerialization.data(withJSONObject: ["value": Self.normalized(value)])
    }

    private var sessionID: String {
        switch self {
        case let .accountStates(_, sessionID),
             let .rate(_, _, sessionID),
             let .delete(_, sessionID):
            sessionID
        }
    }

    /// TMDB accepts 0.5–10 in 0.5 steps; snap any input onto that grid.
    static func normalized(_ value: Double) -> Double {
        let snapped = (value * 2).rounded() / 2
        return min(max(snapped, 0.5), 10)
    }
}
