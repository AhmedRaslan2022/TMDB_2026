//
//  Movie.swift
//  TMDB
//
//  Created by Ahmed Raslan on 18/07/2026.
//

import Foundation

/// A movie as the domain sees it — shared by every feature (Home, Details,
/// Search, Favorites) so features never import each other. Pure value type;
/// wire formats live in each feature's Data layer.
public struct Movie: Identifiable, Hashable, Sendable {
    public let id: Int
    public let title: String
    public let overview: String
    /// TMDB image path (e.g. `/abc.jpg`); resolved against the image base URL
    /// by the presentation layer.
    public let posterPath: String?
    public let backdropPath: String?
    public let releaseDate: Date?
    /// Average vote on TMDB's 0–10 scale.
    public let voteAverage: Double
    public let voteCount: Int
    public let genreIDs: [Int]

    public init(
        id: Int,
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
