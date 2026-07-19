//
//  MovieDetails.swift
//  TMDB
//
//  Created by Ahmed Raslan on 19/07/2026.
//

import Foundation

/// A movie's full detail record. Richer than the shared `Movie` list entity;
/// specific to this feature, so it lives here rather than CoreModels.
public struct MovieDetails: Hashable, Sendable {
    public let id: Int
    public let title: String
    public let overview: String
    public let tagline: String?
    public let posterPath: String?
    public let backdropPath: String?
    public let releaseDate: Date?
    public let runtimeMinutes: Int?
    public let voteAverage: Double
    public let voteCount: Int
    public let genres: [Genre]

    public init(
        id: Int,
        title: String,
        overview: String,
        tagline: String? = nil,
        posterPath: String? = nil,
        backdropPath: String? = nil,
        releaseDate: Date? = nil,
        runtimeMinutes: Int? = nil,
        voteAverage: Double = 0,
        voteCount: Int = 0,
        genres: [Genre] = []
    ) {
        self.id = id
        self.title = title
        self.overview = overview
        self.tagline = tagline
        self.posterPath = posterPath
        self.backdropPath = backdropPath
        self.releaseDate = releaseDate
        self.runtimeMinutes = runtimeMinutes
        self.voteAverage = voteAverage
        self.voteCount = voteCount
        self.genres = genres
    }
}

/// A TMDB genre as named in the details payload.
public struct Genre: Hashable, Sendable, Identifiable {
    public let id: Int
    public let name: String

    public init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
}
