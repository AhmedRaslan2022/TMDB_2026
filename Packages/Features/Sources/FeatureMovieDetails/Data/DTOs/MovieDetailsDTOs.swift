//
//  MovieDetailsDTOs.swift
//  TMDB
//
//  Created by Ahmed Raslan on 19/07/2026.
//

/// Wire shapes of TMDB's appended details response. Internal to the Data
/// layer. Property names are camelCase because the shared decoder converts
/// from snake_case. The appended sections are optional — TMDB omits them if
/// the append parameter is ever dropped.
struct MovieDetailsDTO: Decodable {
    let id: Int
    let title: String
    let overview: String?
    let tagline: String?
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: String?
    let runtime: Int?
    let voteAverage: Double?
    let voteCount: Int?
    let genres: [GenreDTO]?
    let credits: CreditsDTO?
    let videos: VideoListDTO?
    let similar: MovieListSliceDTO?
    let recommendations: MovieListSliceDTO?
}

struct GenreDTO: Decodable {
    let id: Int
    let name: String
}

struct CreditsDTO: Decodable {
    let cast: [CastMemberDTO]?
}

struct CastMemberDTO: Decodable {
    let creditId: String
    let id: Int
    let name: String
    let character: String?
    let profilePath: String?
    let order: Int?
}

struct VideoListDTO: Decodable {
    let results: [VideoDTO]?
}

struct VideoDTO: Decodable {
    let id: String
    let name: String
    let key: String
    let site: String
    let type: String
    let official: Bool?
}

/// The `results` slice of an appended movie list. Deliberately a twin of
/// FeatureHome's page DTO — DTOs are feature-local by design and never
/// shared across features.
struct MovieListSliceDTO: Decodable {
    let results: [SliceMovieDTO]?
}

struct SliceMovieDTO: Decodable {
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
