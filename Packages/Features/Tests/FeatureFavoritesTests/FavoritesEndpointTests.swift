//
//  FavoritesEndpointTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 19/07/2026.
//

import Foundation
import Networking
import Testing
@testable import FeatureFavorites

@Suite("FavoritesEndpoint")
struct FavoritesEndpointTests {
    @Test("list is a GET with no body")
    func listShape() {
        let endpoint = FavoritesEndpoint.list(accountID: 42, sessionID: "s", page: 2)

        #expect(endpoint.path == "/account/42/favorite/movies")
        #expect(endpoint.method == .get)
        #expect(endpoint.body == nil)
    }

    @Test("setFavorite encodes the snake_case media body", arguments: [true, false])
    func setFavoriteBody(isFavorite: Bool) throws {
        let endpoint = FavoritesEndpoint.setFavorite(
            accountID: 42, sessionID: "s", movieID: 550, isFavorite: isFavorite
        )

        #expect(endpoint.method == .post)
        let body = try #require(endpoint.body)
        let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(json["media_type"] as? String == "movie")
        #expect(json["media_id"] as? Int == 550)
        #expect(json["favorite"] as? Bool == isFavorite)
    }
}
