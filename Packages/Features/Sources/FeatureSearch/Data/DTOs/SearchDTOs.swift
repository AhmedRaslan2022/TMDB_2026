//
//  SearchDTOs.swift
//  TMDB
//
//  Created by Ahmed Raslan on 19/07/2026.
//

/// Wire shapes of TMDB's search responses. Internal to the Data layer;
/// deliberate twin of the other features' movie DTOs — Data layers are
/// feature-local and never shared. camelCase because the shared decoder
/// converts from snake_case.
struct SearchPageDTO: Decodable {
    let page: Int
    let results: [SearchMovieDTO]
    let totalPages: Int
}

struct SearchMovieDTO: Decodable {
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
