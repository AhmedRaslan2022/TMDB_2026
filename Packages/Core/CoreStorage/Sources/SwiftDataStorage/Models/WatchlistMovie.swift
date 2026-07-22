//
//  WatchlistMovie.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

import Foundation
import SwiftData

/// A movie on the user's watchlist. Source of truth for offline-first
/// watchlist; synced with the TMDB account when authenticated. Mirrors
/// `FavoriteMovie` — both drive the same generic collection plumbing.
@Model
public final class WatchlistMovie: CollectionMovieModel {
    @Attribute(.unique) public var movieID: Int
    public var title: String
    public var posterPath: String?
    public var addedAt: Date

    public init(movieID: Int, title: String, posterPath: String? = nil, addedAt: Date = .now) {
        self.movieID = movieID
        self.title = title
        self.posterPath = posterPath
        self.addedAt = addedAt
    }
}
