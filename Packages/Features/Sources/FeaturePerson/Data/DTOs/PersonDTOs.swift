//
//  PersonDTOs.swift
//  TMDB
//
//  Created by Ahmed Raslan on 21/07/2026.
//

/// Wire shapes of TMDB's `/person/{id}` appended response. Internal to the Data
/// layer; camelCase because the shared decoder converts from snake_case.
struct PersonDetailsDTO: Decodable {
    let id: Int
    let name: String
    let biography: String?
    let birthday: String?
    let deathday: String?
    let placeOfBirth: String?
    let profilePath: String?
    let knownForDepartment: String?
    let combinedCredits: CombinedCreditsDTO?
    let images: PersonImagesDTO?
}

struct CombinedCreditsDTO: Decodable {
    let cast: [PersonCreditDTO]?
}

/// One combined credit. `mediaType` discriminates movie vs TV; `title`/`name`
/// and `releaseDate`/`firstAirDate` are the movie/TV field pairs.
struct PersonCreditDTO: Decodable {
    let id: Int
    let mediaType: String?
    let title: String?
    let name: String?
    let character: String?
    let overview: String?
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: String?
    let firstAirDate: String?
    let voteAverage: Double?
    let voteCount: Int?
    let genreIds: [Int]?
}

struct PersonImagesDTO: Decodable {
    let profiles: [PersonImageDTO]?
}

struct PersonImageDTO: Decodable {
    let filePath: String
}
