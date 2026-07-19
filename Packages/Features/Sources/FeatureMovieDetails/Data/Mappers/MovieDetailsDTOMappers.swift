//
//  MovieDetailsDTOMappers.swift
//  TMDB
//
//  Created by Ahmed Raslan on 19/07/2026.
//

import CoreModels
import Foundation

extension MovieDetailsDTO {
    /// Maps the appended payload to the domain bundle. Lenient like the rest
    /// of the app's mappers: missing appended sections become empty arrays,
    /// unparseable dates become nil — partial data never fails the screen.
    func toDomain() -> MovieDetailsBundle {
        MovieDetailsBundle(
            details: MovieDetails(
                id: id,
                title: title,
                overview: overview ?? "",
                tagline: tagline.flatMap { $0.isEmpty ? nil : $0 },
                posterPath: posterPath,
                backdropPath: backdropPath,
                releaseDate: releaseDate.flatMap(TMDBDateParser.parse),
                runtimeMinutes: runtime.flatMap { $0 > 0 ? $0 : nil },
                voteAverage: voteAverage ?? 0,
                voteCount: voteCount ?? 0,
                genres: (genres ?? []).map { Genre(id: $0.id, name: $0.name) }
            ),
            cast: mappedCast,
            videos: mappedVideos,
            similar: similar.mappedMovies,
            recommendations: recommendations.mappedMovies
        )
    }

    /// Billing order, stable even when TMDB omits `order`.
    private var mappedCast: [CastMember] {
        (credits?.cast ?? [])
            .sorted { ($0.order ?? .max) < ($1.order ?? .max) }
            .map {
                CastMember(
                    id: $0.creditId,
                    personID: $0.id,
                    name: $0.name,
                    character: $0.character,
                    profilePath: $0.profilePath
                )
            }
    }

    /// Videos from sites the app can present; unknown sites are dropped.
    private var mappedVideos: [MovieVideo] {
        (videos?.results ?? []).compactMap { dto in
            guard let site = MovieVideo.Site(rawValue: dto.site) else { return nil }
            return MovieVideo(
                id: dto.id,
                name: dto.name,
                key: dto.key,
                site: site,
                type: dto.type,
                isOfficial: dto.official ?? false
            )
        }
    }
}

extension MovieListSliceDTO? {
    var mappedMovies: [Movie] {
        (self?.results ?? []).map {
            Movie(
                id: $0.id,
                title: $0.title,
                overview: $0.overview ?? "",
                posterPath: $0.posterPath,
                backdropPath: $0.backdropPath,
                releaseDate: $0.releaseDate.flatMap(TMDBDateParser.parse),
                voteAverage: $0.voteAverage ?? 0,
                voteCount: $0.voteCount ?? 0,
                genreIDs: $0.genreIds ?? []
            )
        }
    }
}

/// Parses TMDB's `yyyy-MM-dd` dates. (Feature-local twin of FeatureHome's
/// parser — Data-layer helpers stay inside their feature.)
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
