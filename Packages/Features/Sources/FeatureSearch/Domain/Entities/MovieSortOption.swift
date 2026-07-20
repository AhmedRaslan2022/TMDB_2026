//
//  MovieSortOption.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

/// How Discover results are ordered. Pure domain — the mapping to TMDB's
/// `sort_by` wire value lives in the Data layer (`DiscoverEndpoint`).
public enum MovieSortOption: Sendable, CaseIterable, Identifiable {
    case popularity
    case rating
    case newest
    case title

    public var id: Self {
        self
    }
}
