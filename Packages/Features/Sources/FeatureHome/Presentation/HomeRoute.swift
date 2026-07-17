//
//  HomeRoute.swift
//  TMDB
//
//  Created by Ahmed Raslan on 17/07/2026.
//

/// Pushable destinations reachable from the Home tab. The app target maps
/// these to views — features never resolve routes themselves.
public enum HomeRoute: Hashable, Sendable {
    /// Movie details for a TMDB movie ID.
    case movieDetails(movieID: Int)
}
