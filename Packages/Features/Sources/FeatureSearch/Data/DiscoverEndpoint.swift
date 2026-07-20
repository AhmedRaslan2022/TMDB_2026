//
//  DiscoverEndpoint.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

import Foundation
import Networking

/// `GET /discover/movie` — filtered, sorted movie browse. Translates the pure
/// `DiscoverFilters` into TMDB's query parameters, including the `sort_by`
/// wire values the domain enum deliberately doesn't carry.
struct DiscoverEndpoint: Endpoint {
    let filters: DiscoverFilters
    let page: Int

    /// A quality floor so rating-led browses aren't dominated by titles with a
    /// perfect score off a handful of votes. Only applied when the result set
    /// is ordered or filtered by rating.
    private static let ratingVoteFloor = 200

    var path: String {
        "/discover/movie"
    }

    var queryItems: [URLQueryItem] {
        var items = [
            URLQueryItem(name: "sort_by", value: Self.sortValue(filters.sort)),
            URLQueryItem(name: "include_adult", value: "false"),
            URLQueryItem(name: "page", value: String(page)),
        ]
        if !filters.genreIDs.isEmpty {
            // Sorted for a stable, testable query; comma = AND in TMDB.
            let ids = filters.genreIDs.sorted().map(String.init).joined(separator: ",")
            items.append(URLQueryItem(name: "with_genres", value: ids))
        }
        if let year = filters.year {
            items.append(URLQueryItem(name: "primary_release_year", value: String(year)))
        }
        if let minimumRating = filters.minimumRating {
            items.append(URLQueryItem(name: "vote_average.gte", value: String(minimumRating)))
        }
        if filters.minimumRating != nil || filters.sort == .rating {
            items.append(URLQueryItem(name: "vote_count.gte", value: String(Self.ratingVoteFloor)))
        }
        return items
    }

    private static func sortValue(_ sort: MovieSortOption) -> String {
        switch sort {
        case .popularity: "popularity.desc"
        case .rating: "vote_average.desc"
        case .newest: "primary_release_date.desc"
        case .title: "title.asc"
        }
    }
}
