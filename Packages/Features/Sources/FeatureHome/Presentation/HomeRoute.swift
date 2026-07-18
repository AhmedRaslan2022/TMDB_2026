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
}
