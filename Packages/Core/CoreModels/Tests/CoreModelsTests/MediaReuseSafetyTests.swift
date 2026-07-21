//
//  MediaReuseSafetyTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 21/07/2026.
//

import Testing
@testable import CoreModels

/// Reuse-safety (task 6.6): the same `MediaItem`/`MoviePage` contract must serve
/// movies and TV identically, so one use case, page type, and grid work for both
/// without divergence.
@Suite("Media reuse safety")
struct MediaReuseSafetyTests {
    private func item(_ id: Int, _ kind: MediaKind) -> MediaItem {
        MediaItem(id: id, mediaType: kind, title: "T\(id)", overview: "")
    }

    @Test("a page can hold movies and TV shows interchangeably, keeping each kind")
    func mixedPageKeepsKinds() {
        let page = MoviePage(page: 1, movies: [item(1, .movie), item(2, .tv)], totalPages: 2)

        #expect(page.movies.map(\.mediaType) == [.movie, .tv])
        #expect(page.hasMorePages, "pagination is identical regardless of the items' media kind")
    }

    @Test("pagination math is media-agnostic", arguments: [
        (1, 3, true),
        (3, 3, false),
        (5, 3, false),
    ])
    func paginationUniform(page: Int, total: Int, hasMore: Bool) {
        // Same MoviePage for a TV page as for a movie page.
        let tvPage = MoviePage(page: page, movies: [item(1, .tv)], totalPages: total)
        #expect(tvPage.hasMorePages == hasMore)
    }

    @Test("mediaType is part of identity: same id, different kind are DISTINCT values")
    func kindDistinguishesEquality() {
        #expect(item(550, .movie) != item(550, .tv))
    }

    @Test("but Identifiable id collides across kinds — mixed collections must key on kind+id")
    func identifiableIdCollidesAcrossKinds() {
        // A movie and a TV show can share the same TMDB id; `Identifiable.id`
        // is just that Int, so a list mixing kinds (e.g. a person's
        // filmography) must NOT key on `MediaItem.id` alone — this is why
        // `PersonCredit.id` is composed of `mediaType` + `id`.
        #expect(item(550, .movie).id == item(550, .tv).id, "the collision that composite ids must guard against")
    }
}
