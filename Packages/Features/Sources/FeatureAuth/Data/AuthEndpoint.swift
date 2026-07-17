//
//  AuthEndpoint.swift
//  TMDB
//
//  Created by Ahmed Raslan on 17/07/2026.
//

import Foundation
import Networking

/// TMDB v3 authentication endpoints.
enum AuthEndpoint: Endpoint {
    case createRequestToken
    case createSession(requestToken: String)
    case createGuestSession
    case deleteSession(sessionID: String)

    var path: String {
        switch self {
        case .createRequestToken: "/authentication/token/new"
        case .createSession: "/authentication/session/new"
        case .createGuestSession: "/authentication/guest_session/new"
        case .deleteSession: "/authentication/session"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .createRequestToken, .createGuestSession: .get
        case .createSession: .post
        case .deleteSession: .delete
        }
    }

    var body: Data? {
        switch self {
        case .createRequestToken, .createGuestSession:
            nil
        case let .createSession(requestToken):
            // Encoding a [String: String] cannot fail; try? is unreachable.
            try? JSONEncoder().encode(["request_token": requestToken])
        case let .deleteSession(sessionID):
            try? JSONEncoder().encode(["session_id": sessionID])
        }
    }
}
