//
//  MoviePage.swift
//  TMDB
//
//  Created by Ahmed Raslan on 18/07/2026.
//

/// One page of a paginated movie list, as TMDB serves them.
public struct MoviePage: Hashable, Sendable {
    public let page: Int
    public let movies: [Movie]
    public let totalPages: Int

    public init(page: Int, movies: [Movie], totalPages: Int) {
        self.page = page
        self.movies = movies
        self.totalPages = totalPages
    }

    /// `true` while TMDB has further pages to fetch.
    public var hasMorePages: Bool {
        page < totalPages
    }
}
