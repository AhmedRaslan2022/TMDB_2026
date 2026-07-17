//
//  FavoriteMovie.swift
//  TMDB
//
//  Created by Ahmed Raslan on 17/07/2026.
//

import Foundation
import SwiftData

/// A movie the user marked as favorite. Source of truth for offline-first
/// favorites; synced with the TMDB account when authenticated (Sprint 4).
@Model
public final class FavoriteMovie {
    /// TMDB movie identifier.
    @Attribute(.unique) public var movieID: Int
    public var title: String
    public var posterPath: String?
    /// When the user favorited it locally — drives sort order.
    public var addedAt: Date

    public init(movieID: Int, title: String, posterPath: String? = nil, addedAt: Date = .now) {
        self.movieID = movieID
        self.title = title
        self.posterPath = posterPath
        self.addedAt = addedAt
    }
}
