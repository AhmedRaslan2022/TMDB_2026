//
//  FavoritesDTOMappers.swift
//  TMDB
//
//  Created by Ahmed Raslan on 19/07/2026.
//

import CoreModels
import Foundation

extension FavoritesPageDTO {
    func toDomain() -> MoviePage {
        MoviePage(page: page, movies: results.map { $0.toDomain() }, totalPages: totalPages)
    }
}

extension FavoriteMovieDTO {
    /// Lenient like the app's other mappers: absent optionals get zero-values,
    /// unparseable dates become nil.
    func toDomain() -> Movie {
        Movie(
            id: id,
            title: title,
            overview: overview ?? "",
            posterPath: posterPath,
            backdropPath: backdropPath,
            releaseDate: releaseDate.flatMap(TMDBDateParser.parse),
            voteAverage: voteAverage ?? 0,
            voteCount: voteCount ?? 0,
            genreIDs: genreIds ?? []
        )
    }
}

/// Parses TMDB's `yyyy-MM-dd` dates. (Feature-local twin — Data-layer helpers
/// stay inside their feature.)
enum TMDBDateParser {
    private static let strategy = Date.ParseStrategy(
        format: "\(year: .defaultDigits)-\(month: .twoDigits)-\(day: .twoDigits)",
        locale: Locale(identifier: "en_US_POSIX"),
        timeZone: .gmt
    )

    static func parse(_ string: String) -> Date? {
        try? Date(string, strategy: strategy)
    }
}
