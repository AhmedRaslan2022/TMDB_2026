//
//  GenresEndpoint.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

import Networking

/// `GET /genre/movie/list` — the movie genre catalog for the filter picker.
struct GenresEndpoint: Endpoint {
    var path: String {
        "/genre/movie/list"
    }
}
