//
//  DiscoverEndpointTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

import Foundation
import Networking
import Testing
@testable import FeatureSearch

@Suite("DiscoverEndpoint query building")
struct DiscoverEndpointTests {
    private func value(_ endpoint: DiscoverEndpoint, _ name: String) -> String? {
        endpoint.queryItems.first { $0.name == name }?.value
    }

    private func names(_ endpoint: DiscoverEndpoint) -> [String] {
        endpoint.queryItems.map(\.name)
    }

    @Test("default filters: popularity sort, adult excluded, no refinements")
    func defaults() {
        let endpoint = DiscoverEndpoint(filters: DiscoverFilters(), page: 1)

        #expect(endpoint.path == "/discover/movie")
        #expect(value(endpoint, "sort_by") == "popularity.desc")
        #expect(value(endpoint, "include_adult") == "false")
        #expect(value(endpoint, "page") == "1")
        #expect(names(endpoint).contains("with_genres") == false)
        #expect(names(endpoint).contains("primary_release_year") == false)
        #expect(names(endpoint).contains("vote_average.gte") == false)
        // No rating filter and not rating-sorted → no vote-count floor.
        #expect(names(endpoint).contains("vote_count.gte") == false)
    }

    @Test("sort options map to TMDB sort_by values", arguments: [
        (MovieSortOption.popularity, "popularity.desc"),
        (MovieSortOption.rating, "vote_average.desc"),
        (MovieSortOption.newest, "primary_release_date.desc"),
        (MovieSortOption.title, "title.asc"),
    ])
    func sortMapping(sort: MovieSortOption, expected: String) {
        let endpoint = DiscoverEndpoint(filters: DiscoverFilters(sort: sort), page: 1)
        #expect(value(endpoint, "sort_by") == expected)
    }

    @Test("genre ids are ANDed as a sorted comma list")
    func genres() {
        let endpoint = DiscoverEndpoint(filters: DiscoverFilters(genreIDs: [35, 28, 12]), page: 2)

        #expect(value(endpoint, "with_genres") == "12,28,35")
        #expect(value(endpoint, "page") == "2")
    }

    @Test("year and minimum rating become their TMDB params")
    func yearAndRating() {
        let endpoint = DiscoverEndpoint(filters: DiscoverFilters(year: 1999, minimumRating: 8), page: 1)

        #expect(value(endpoint, "primary_release_year") == "1999")
        #expect(value(endpoint, "vote_average.gte") == "8.0")
    }

    @Test("a minimum-rating filter adds the vote-count quality floor")
    func ratingFilterAddsVoteFloor() {
        let endpoint = DiscoverEndpoint(filters: DiscoverFilters(minimumRating: 7), page: 1)
        #expect(value(endpoint, "vote_count.gte") == "200")
    }

    @Test("rating sort adds the vote-count floor even without a rating filter")
    func ratingSortAddsVoteFloor() {
        let endpoint = DiscoverEndpoint(filters: DiscoverFilters(sort: .rating), page: 1)
        #expect(value(endpoint, "vote_count.gte") == "200")
    }

    @Test("genres endpoint routes to the movie genre list")
    func genresEndpoint() {
        #expect(GenresEndpoint().path == "/genre/movie/list")
    }
}
