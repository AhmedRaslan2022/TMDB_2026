//
//  TVShowDetails.swift
//  TMDB
//
//  Created by Ahmed Raslan on 21/07/2026.
//

import CoreModels
import Foundation

/// A TV show's detail page as the domain sees it. The TV-specific counterpart
/// to `MovieDetails` (seasons/episodes/first-air date replace runtime/release
/// date); list-shaped relations reuse the generalized `MediaItem`.
public struct TVShowDetails: Identifiable, Hashable, Sendable {
    public let id: Int
    public let name: String
    public let overview: String
    public let tagline: String?
    public let posterPath: String?
    public let backdropPath: String?
    public let firstAirDate: Date?
    public let numberOfSeasons: Int
    public let numberOfEpisodes: Int
    public let genres: [String]
    public let voteAverage: Double
    public let voteCount: Int

    public init(
        id: Int,
        name: String,
        overview: String,
        tagline: String? = nil,
        posterPath: String? = nil,
        backdropPath: String? = nil,
        firstAirDate: Date? = nil,
        numberOfSeasons: Int = 0,
        numberOfEpisodes: Int = 0,
        genres: [String] = [],
        voteAverage: Double = 0,
        voteCount: Int = 0
    ) {
        self.id = id
        self.name = name
        self.overview = overview
        self.tagline = tagline
        self.posterPath = posterPath
        self.backdropPath = backdropPath
        self.firstAirDate = firstAirDate
        self.numberOfSeasons = numberOfSeasons
        self.numberOfEpisodes = numberOfEpisodes
        self.genres = genres
        self.voteAverage = voteAverage
        self.voteCount = voteCount
    }
}

/// One TV details fetch: the show plus its related carousels, mapped to the
/// shared `MediaItem` (kind `.tv`) so the same grid renders them.
public struct TVShowDetailsBundle: Hashable, Sendable {
    public let details: TVShowDetails
    public let similar: [MediaItem]
    public let recommendations: [MediaItem]

    public init(details: TVShowDetails, similar: [MediaItem] = [], recommendations: [MediaItem] = []) {
        self.details = details
        self.similar = similar
        self.recommendations = recommendations
    }
}
