//
//  MovieCollection.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

/// A synced saved-movie collection. Favorites and watchlist share the same
/// offline-first plumbing (local store + TMDB sync); they differ only by the
/// TMDB path segment and the toggle body key this describes.
public enum MovieCollection: String, CaseIterable, Sendable {
    case favorites
    case watchlist

    /// TMDB account sub-path (`/account/{id}/{segment}`, `…/{segment}/movies`).
    var remoteSegment: String {
        switch self {
        case .favorites: "favorite"
        case .watchlist: "watchlist"
        }
    }

    /// The membership key in the toggle POST body.
    var bodyKey: String {
        switch self {
        case .favorites: "favorite"
        case .watchlist: "watchlist"
        }
    }
}
