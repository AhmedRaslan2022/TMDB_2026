//
//  MovieListEndpoint.swift
//  TMDB
//
//  Created by Ahmed Raslan on 18/07/2026.
//

import Foundation
import Networking

/// TMDB v3 movie-list endpoints, one page at a time.
struct MovieListEndpoint: Endpoint {
    let list: MovieList
    let page: Int

    var path: String {
        switch list {
        case let .trending(window): "/trending/movie/\(window.rawValue)"
        case .popular: "/movie/popular"
        case .nowPlaying: "/movie/now_playing"
        case .upcoming: "/movie/upcoming"
        case .topRated: "/movie/top_rated"
        }
    }

    var queryItems: [URLQueryItem] {
        [URLQueryItem(name: "page", value: String(page))]
    }
}
