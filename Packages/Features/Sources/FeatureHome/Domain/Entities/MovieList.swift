//
//  MovieList.swift
//  TMDB
//
//  Created by Ahmed Raslan on 18/07/2026.
//

import CoreModels

/// The movie lists the Home feature can fetch. One parameterized list type
/// instead of five clone use cases — the 3.2 `TaskGroup` fans out over these.
public enum MovieList: Hashable, Sendable {
    case trending(TrendingWindow)
    case popular
    case nowPlaying
    case upcoming
    case topRated
}
