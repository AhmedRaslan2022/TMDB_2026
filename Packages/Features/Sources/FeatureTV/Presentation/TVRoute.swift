//
//  TVRoute.swift
//  TMDB
//
//  Created by Ahmed Raslan on 21/07/2026.
//

/// Pushable destinations reachable from the TV tab. The app target maps these
/// to views — features never resolve routes themselves.
public enum TVRoute: Hashable, Sendable {
    /// TV show details for a TMDB show ID.
    case showDetails(showID: Int)
}
