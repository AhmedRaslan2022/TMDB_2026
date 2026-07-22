//
//  MovieCollectionEndpointTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

import Foundation
import Networking
import Testing
@testable import FeatureFavorites

@Suite("MovieCollectionEndpoint")
struct MovieCollectionEndpointTests {
    @Test("list route + query per collection", arguments: [
        (MovieCollection.favorites, "/account/42/favorite/movies"),
        (MovieCollection.watchlist, "/account/42/watchlist/movies"),
    ])
    func listRoute(collection: MovieCollection, expectedPath: String) {
        let endpoint = MovieCollectionEndpoint.list(collection: collection, accountID: 42, sessionID: "s", page: 1)

        #expect(endpoint.path == expectedPath)
        #expect(endpoint.method == .get)
        #expect(endpoint.queryItems.contains(URLQueryItem(name: "session_id", value: "s")))
        #expect(endpoint.queryItems.contains(URLQueryItem(name: "sort_by", value: "created_at.desc")))
    }

    @Test("setMembership POSTs the collection-keyed body", arguments: [
        (MovieCollection.favorites, "favorite"),
        (MovieCollection.watchlist, "watchlist"),
    ])
    func setMembershipBody(collection: MovieCollection, bodyKey: String) throws {
        let endpoint = MovieCollectionEndpoint.setMembership(
            collection: collection, accountID: 42, sessionID: "s", movieID: 550, isMember: true
        )

        #expect(endpoint.path == "/account/42/\(collection.remoteSegment)")
        #expect(endpoint.method == .post)
        let body = try #require(endpoint.body)
        let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(json["media_type"] as? String == "movie")
        #expect(json["media_id"] as? Int == 550)
        #expect(json[bodyKey] as? Bool == true)
    }
}
