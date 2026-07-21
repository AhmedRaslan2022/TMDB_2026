//
//  FavoritesRoute.swift
//  TMDB
//
//  Created by Ahmed Raslan on 17/07/2026.
//

/// Pushable destinations reachable from the Favorites tab. The app target
/// maps these to views — features never resolve routes themselves.
public enum FavoritesRoute: Hashable, Sendable {
    /// Movie details for a TMDB movie ID.
    case movieDetails(movieID: Int)
    /// TV show details — reachable via a person's TV filmography credit (6.5).
    case tvDetails(showID: Int)
    /// Person/actor details for a TMDB person ID.
    case person(personID: Int)
}
