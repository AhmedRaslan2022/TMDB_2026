//
//  FavoritesDTOs.swift
//  TMDB
//
//  Created by Ahmed Raslan on 19/07/2026.
//

/// Wire shape of the account favorites list. Internal to the Data layer;
/// feature-local twin of the other movie-page DTOs (Data layers are never
/// shared across features). camelCase because the shared decoder converts
/// from snake_case.
struct FavoritesPageDTO: Decodable {
    let page: Int
    let results: [FavoriteMovieDTO]
    let totalPages: Int
}

struct FavoriteMovieDTO: Decodable {
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
