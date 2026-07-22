//
//  TVEndpoints.swift
//  TMDB
//
//  Created by Ahmed Raslan on 21/07/2026.
//

import Foundation
import Networking

/// TMDB v3 TV-list endpoints, one page at a time.
struct TVListEndpoint: Endpoint {
    let list: TVList
    let page: Int

    var path: String {
        switch list {
        case .onTheAir: "/tv/on_the_air"
        case .popular: "/tv/popular"
        case .topRated: "/tv/top_rated"
        }
    }

    var queryItems: [URLQueryItem] {
        [URLQueryItem(name: "page", value: String(page))]
    }
}

/// `GET /tv/{id}` with `append_to_response`, so the show and its related
/// carousels arrive in one request.
struct TVDetailsEndpoint: Endpoint {
    let showID: Int

    var path: String {
        "/tv/\(showID)"
    }

    var queryItems: [URLQueryItem] {
        [URLQueryItem(name: "append_to_response", value: "similar,recommendations")]
    }
}
