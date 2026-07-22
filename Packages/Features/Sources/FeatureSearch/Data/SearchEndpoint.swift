//
//  SearchEndpoint.swift
//  TMDB
//
//  Created by Ahmed Raslan on 19/07/2026.
//

import Foundation
import Networking

/// `GET /search/movie` — TMDB free-text movie search, one page at a time.
struct SearchEndpoint: Endpoint {
    let query: String
    let page: Int

    var path: String {
        "/search/movie"
    }

    var queryItems: [URLQueryItem] {
        [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "include_adult", value: "false"),
        ]
    }
}
