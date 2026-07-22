//
//  MovieDetailsEndpoint.swift
//  TMDB
//
//  Created by Ahmed Raslan on 19/07/2026.
//

import Foundation
import Networking

/// `GET /movie/{id}` with `append_to_response`, so details, credits, videos,
/// similar and recommendations arrive as one payload — one request instead
/// of five.
struct MovieDetailsEndpoint: Endpoint {
    let movieID: Int

    var path: String {
        "/movie/\(movieID)"
    }

    var queryItems: [URLQueryItem] {
        [URLQueryItem(name: "append_to_response", value: "credits,videos,similar,recommendations")]
    }
}
