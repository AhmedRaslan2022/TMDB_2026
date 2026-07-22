//
//  DiscoverFilters.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

/// The advanced-search criteria a Discover query is built from. All fields are
/// optional refinements over a default popularity browse.
public struct DiscoverFilters: Sendable, Equatable {
    /// Genre IDs a movie must match (TMDB ANDs them via `with_genres`).
    public var genreIDs: Set<Int>
    /// Exact `primary_release_year`, or `nil` for any year.
    public var year: Int?
    /// Minimum `vote_average` (0.5–10), or `nil` for any rating.
    public var minimumRating: Double?
    /// Result ordering.
    public var sort: MovieSortOption

    public init(
        genreIDs: Set<Int> = [],
        year: Int? = nil,
        minimumRating: Double? = nil,
        sort: MovieSortOption = .popularity
    ) {
        self.genreIDs = genreIDs
        self.year = year
        self.minimumRating = minimumRating
        self.sort = sort
    }

    /// Whether any refinement is applied over the default popularity browse.
    public var isActive: Bool {
        !genreIDs.isEmpty || year != nil || minimumRating != nil || sort != .popularity
    }
}
