//
//  CachedMovie.swift
//  TMDB
//
//  Created by Ahmed Raslan on 17/07/2026.
//

import Foundation
import SwiftData

/// Locally cached movie summary enabling offline browsing of previously
/// fetched lists.
@Model
public final class CachedMovie {
    /// TMDB movie identifier.
    @Attribute(.unique) public var movieID: Int
    public var title: String
    public var overview: String
    public var posterPath: String?
    public var backdropPath: String?
    public var releaseDate: Date?
    /// TMDB vote average, 0...10.
    public var voteAverage: Double
    /// When this row was written — drives cache invalidation.
    public var cachedAt: Date

    public init(
        movieID: Int,
        title: String,
        overview: String,
        posterPath: String? = nil,
        backdropPath: String? = nil,
        releaseDate: Date? = nil,
        voteAverage: Double = 0,
        cachedAt: Date = .now
    ) {
        self.movieID = movieID
        self.title = title
        self.overview = overview
        self.posterPath = posterPath
        self.backdropPath = backdropPath
        self.releaseDate = releaseDate
        self.voteAverage = voteAverage
        self.cachedAt = cachedAt
    }
}
