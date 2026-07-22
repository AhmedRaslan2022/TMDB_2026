//
//  GenreDTOs.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

/// Wire shape of `GET /genre/movie/list`. Internal to the Data layer.
struct GenreListDTO: Decodable {
    let genres: [GenreDTO]
}

struct GenreDTO: Decodable {
    let id: Int
    let name: String
}

extension GenreListDTO {
    func toDomain() -> [MovieGenre] {
        genres.map { MovieGenre(id: $0.id, name: $0.name) }
    }
}
