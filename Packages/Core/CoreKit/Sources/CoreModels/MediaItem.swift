//
//  MediaItem.swift
//  TMDB
//
//  Created by Ahmed Raslan on 18/07/2026.
//

import Foundation

/// A catalog entry as the domain sees it — a movie or a TV show. Shared by every
/// feature (Home, Details, Search, Favorites) so features never import each
/// other. Pure value type; wire formats live in each feature's Data layer.
///
/// The fields are the media-neutral shape both TMDB types map onto: TV's `name`
/// and `first_air_date` become `title` and `releaseDate` in each feature's
/// mapper, so one entity, use case, and grid serve both kinds (Sprint 6).
public struct MediaItem: Identifiable, Hashable, Sendable {
    public let id: Int
    /// Whether this entry is a movie or a TV show.
    public let mediaType: MediaKind
    /// Movie title or TV show name.
    public let title: String
    public let overview: String
    /// TMDB image path (e.g. `/abc.jpg`); resolved against the image base URL
    /// by the presentation layer.
    public let posterPath: String?
    public let backdropPath: String?
    /// Movie release date or TV first-air date.
    public let releaseDate: Date?
    /// Average vote on TMDB's 0–10 scale.
    public let voteAverage: Double
    public let voteCount: Int
    public let genreIDs: [Int]

    public init(
        id: Int,
        mediaType: MediaKind = .movie,
        title: String,
        overview: String,
        posterPath: String? = nil,
        backdropPath: String? = nil,
        releaseDate: Date? = nil,
        voteAverage: Double = 0,
        voteCount: Int = 0,
        genreIDs: [Int] = []
    ) {
        self.id = id
        self.mediaType = mediaType
        self.title = title
        self.overview = overview
        self.posterPath = posterPath
        self.backdropPath = backdropPath
        self.releaseDate = releaseDate
        self.voteAverage = voteAverage
        self.voteCount = voteCount
        self.genreIDs = genreIDs
    }
}

/// Compatibility alias for the movie-era name. New code prefers `MediaItem`;
/// this keeps the existing movie call sites (Home, Search, Favorites, Details)
/// unchanged while the TV generalization lands. Movie construction defaults
/// `mediaType` to `.movie`.
public typealias Movie = MediaItem
