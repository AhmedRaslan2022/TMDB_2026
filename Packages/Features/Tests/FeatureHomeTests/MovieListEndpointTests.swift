//
//  MovieListEndpointTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 18/07/2026.
//

import CoreModels
import Foundation
import Testing
@testable import FeatureHome

@Suite("MovieListEndpoint")
struct MovieListEndpointTests {
    @Test("paths match TMDB v3 list routes", arguments: [
        (MovieList.trending(.day), "/trending/movie/day"),
        (MovieList.trending(.week), "/trending/movie/week"),
        (MovieList.popular, "/movie/popular"),
        (MovieList.nowPlaying, "/movie/now_playing"),
        (MovieList.upcoming, "/movie/upcoming"),
        (MovieList.topRated, "/movie/top_rated"),
    ])
    func paths(list: MovieList, expected: String) {
        #expect(MovieListEndpoint(list: list, page: 1).path == expected)
    }

    @Test("page rides as a query item; method defaults to GET with no body")
    func pageQuery() {
        let endpoint = MovieListEndpoint(list: .popular, page: 3)

        #expect(endpoint.queryItems == [URLQueryItem(name: "page", value: "3")])
        #expect(endpoint.method == .get)
        #expect(endpoint.body == nil)
    }
}
