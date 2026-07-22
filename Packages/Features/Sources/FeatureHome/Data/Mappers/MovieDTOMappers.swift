//
//  MovieDTOMappers.swift
//  TMDB
//
//  Created by Ahmed Raslan on 18/07/2026.
//

import CoreModels
import Foundation

extension MovieDTO {
    /// Maps to the shared domain entity. Lenient by design: a missing or
    /// unparseable release date becomes `nil` rather than failing the whole
    /// page — TMDB list items routinely ship partial data.
    func toDomain() -> Movie {
        Movie(
            id: id,
            title: title,
            overview: overview ?? "",
            posterPath: posterPath,
            backdropPath: backdropPath,
            releaseDate: releaseDate.flatMap(Self.parseReleaseDate),
            voteAverage: voteAverage ?? 0,
            voteCount: voteCount ?? 0,
            genreIDs: genreIds ?? []
        )
    }

    /// Parses TMDB's `yyyy-MM-dd` release dates. `Date.ParseStrategy` is
    /// `Sendable`, so unlike `DateFormatter` it can be cached safely.
    private static let releaseDateStrategy = Date.ParseStrategy(
        format: "\(year: .defaultDigits)-\(month: .twoDigits)-\(day: .twoDigits)",
        locale: Locale(identifier: "en_US_POSIX"),
        timeZone: .gmt
    )

    private static func parseReleaseDate(_ string: String) -> Date? {
        try? Date(string, strategy: releaseDateStrategy)
    }
}

extension MoviePageDTO {
    func toDomain() -> MoviePage {
        MoviePage(
            page: page,
            movies: results.map { $0.toDomain() },
            totalPages: totalPages
        )
    }
}
