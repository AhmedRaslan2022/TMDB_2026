//
//  PersonDTOMappers.swift
//  TMDB
//
//  Created by Ahmed Raslan on 21/07/2026.
//

import CoreModels
import Foundation

extension PersonCreditDTO {
    /// Maps one credit to a `PersonCredit`, or `nil` if it isn't a movie/TV
    /// title we can render (e.g. an unexpected media type). The media becomes a
    /// shared `MediaItem` with the right kind, so filmography reuses the grid.
    func toDomain() -> PersonCredit? {
        let kind: MediaKind
        switch mediaType {
        case "movie": kind = .movie
        case "tv": kind = .tv
        default: return nil
        }
        let media = MediaItem(
            id: id,
            mediaType: kind,
            title: title ?? name ?? "",
            overview: overview ?? "",
            posterPath: posterPath,
            backdropPath: backdropPath,
            releaseDate: (releaseDate ?? firstAirDate).flatMap(PersonDateParser.parse),
            voteAverage: voteAverage ?? 0,
            voteCount: voteCount ?? 0,
            genreIDs: genreIds ?? []
        )
        return PersonCredit(media: media, character: (character?.isEmpty ?? true) ? nil : character)
    }
}

extension PersonDetailsDTO {
    func toDomainBundle() -> PersonDetailsBundle {
        // Most-notable first; de-dupe the same title appearing under multiple
        // credits (TMDB lists e.g. recurring TV roles repeatedly).
        var seen = Set<String>()
        let filmography = (combinedCredits?.cast ?? [])
            .compactMap { $0.toDomain() }
            .sorted { $0.media.voteCount > $1.media.voteCount }
            .filter { seen.insert($0.id).inserted }

        return PersonDetailsBundle(
            person: Person(
                id: id,
                name: name,
                biography: biography ?? "",
                birthday: birthday.flatMap(PersonDateParser.parse),
                deathday: deathday.flatMap(PersonDateParser.parse),
                placeOfBirth: placeOfBirth,
                profilePath: profilePath,
                knownForDepartment: knownForDepartment
            ),
            filmography: filmography,
            imagePaths: (images?.profiles ?? []).map(\.filePath)
        )
    }
}

/// Parses TMDB's `yyyy-MM-dd` dates. Feature-local twin — Data-layer helpers
/// stay inside their feature.
enum PersonDateParser {
    private static let strategy = Date.ParseStrategy(
        format: "\(year: .defaultDigits)-\(month: .twoDigits)-\(day: .twoDigits)",
        locale: Locale(identifier: "en_US_POSIX"),
        timeZone: .gmt
    )

    static func parse(_ string: String) -> Date? {
        try? Date(string, strategy: strategy)
    }
}
