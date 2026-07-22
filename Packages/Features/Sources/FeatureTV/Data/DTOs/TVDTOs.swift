//
//  TVDTOs.swift
//  TMDB
//
//  Created by Ahmed Raslan on 21/07/2026.
//

/// Wire shapes of TMDB's TV responses. Internal to the Data layer; camelCase
/// because the shared decoder converts from snake_case. TV uses `name` and
/// `first_air_date` where movies use `title`/`release_date` — the mappers
/// normalize both into the shared `MediaItem`.
struct TVShowDTO: Decodable {
    let id: Int
    let name: String
    let overview: String?
    let posterPath: String?
    let backdropPath: String?
    let firstAirDate: String?
    let voteAverage: Double?
    let voteCount: Int?
    let genreIds: [Int]?
}

struct TVPageDTO: Decodable {
    let page: Int
    let results: [TVShowDTO]
    let totalPages: Int
}

struct TVGenreDTO: Decodable {
    let id: Int
    let name: String
}

struct TVShowDetailsDTO: Decodable {
    let id: Int
    let name: String
    let overview: String?
    let tagline: String?
    let posterPath: String?
    let backdropPath: String?
    let firstAirDate: String?
    let numberOfSeasons: Int?
    let numberOfEpisodes: Int?
    let voteAverage: Double?
    let voteCount: Int?
    let genres: [TVGenreDTO]?
    let similar: TVPageDTO?
    let recommendations: TVPageDTO?
}
