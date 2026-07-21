//
//  TVDTOMappers.swift
//  TMDB
//
//  Created by Ahmed Raslan on 21/07/2026.
//

import CoreModels
import Foundation

extension TVShowDTO {
    /// Maps to the shared `MediaItem` with kind `.tv`: TV's `name` and
    /// `first_air_date` become the media-neutral `title`/`releaseDate`, so the
    /// same grid and pagination serve both media types.
    func toDomain() -> MediaItem {
        MediaItem(
            id: id,
            mediaType: .tv,
            title: name,
            overview: overview ?? "",
            posterPath: posterPath,
            backdropPath: backdropPath,
            releaseDate: firstAirDate.flatMap(TVDateParser.parse),
            voteAverage: voteAverage ?? 0,
            voteCount: voteCount ?? 0,
            genreIDs: genreIds ?? []
        )
    }
}

extension TVPageDTO {
    func toDomain() -> MoviePage {
        MoviePage(page: page, movies: results.map { $0.toDomain() }, totalPages: totalPages)
    }
}

extension TVShowDetailsDTO {
    func toDomainBundle() -> TVShowDetailsBundle {
        TVShowDetailsBundle(
            details: TVShowDetails(
                id: id,
                name: name,
                overview: overview ?? "",
                tagline: (tagline?.isEmpty ?? true) ? nil : tagline,
                posterPath: posterPath,
                backdropPath: backdropPath,
                firstAirDate: firstAirDate.flatMap(TVDateParser.parse),
                numberOfSeasons: numberOfSeasons ?? 0,
                numberOfEpisodes: numberOfEpisodes ?? 0,
                genres: (genres ?? []).map(\.name),
                voteAverage: voteAverage ?? 0,
                voteCount: voteCount ?? 0
            ),
            similar: (similar?.results ?? []).map { $0.toDomain() },
            recommendations: (recommendations?.results ?? []).map { $0.toDomain() }
        )
    }
}

/// Parses TMDB's `yyyy-MM-dd` dates. Feature-local twin — Data-layer helpers
/// stay inside their feature.
enum TVDateParser {
    private static let strategy = Date.ParseStrategy(
        format: "\(year: .defaultDigits)-\(month: .twoDigits)-\(day: .twoDigits)",
        locale: Locale(identifier: "en_US_POSIX"),
        timeZone: .gmt
    )

    static func parse(_ string: String) -> Date? {
        try? Date(string, strategy: strategy)
    }
}
