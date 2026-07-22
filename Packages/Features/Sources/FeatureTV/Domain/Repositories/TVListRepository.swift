//
//  TVListRepository.swift
//  TMDB
//
//  Created by Ahmed Raslan on 21/07/2026.
//

import CoreModels

/// Access to TMDB's TV lists. Returns the SAME `MoviePage`/`MediaItem` movies
/// use — the generalization (6.1) is what lets one page type serve both.
public protocol TVListRepository: Sendable {
    /// One page of `list`, 1-based like the TMDB API.
    func shows(in list: TVList, page: Int) async throws -> MoviePage
}
