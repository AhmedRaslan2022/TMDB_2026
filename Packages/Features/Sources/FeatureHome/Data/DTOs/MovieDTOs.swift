//
//  MovieDTOs.swift
//  TMDB
//
//  Created by Ahmed Raslan on 18/07/2026.
//

/// Wire shapes of TMDB's movie-list responses. Internal to the Data layer.
/// Property names are camelCase because the shared decoder converts from
/// snake_case; fields TMDB sometimes omits are optional.
struct MovieDTO: Decodable {
    let id: Int
    let title: String
    let overview: String?
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: String?
    let voteAverage: Double?
    let voteCount: Int?
    let genreIds: [Int]?
}

struct MoviePageDTO: Decodable {
    let page: Int
    let results: [MovieDTO]
    let totalPages: Int
}
