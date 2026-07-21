//
//  HomeRoute.swift
//  TMDB
//
//  Created by Ahmed Raslan on 17/07/2026.
//

import CoreModels

/// Pushable destinations reachable from the Home tab. The app target maps
/// these to views — features never resolve routes themselves.
public enum HomeRoute: Hashable, Sendable {
    /// Movie details for a TMDB movie ID.
    case movieDetails(movieID: Int)
    /// Paginated "see all" list for a home section. The trending window is
    /// captured at push time.
    case seeAll(section: HomeSection, window: TrendingWindow)
    /// TV show details — reachable when a person's filmography credit is a TV
    /// title (the cast → person → their-titles deep graph, Sprint 6.5).
    case tvDetails(showID: Int)
    /// Person/actor details for a TMDB person ID.
    case person(personID: Int)
}
