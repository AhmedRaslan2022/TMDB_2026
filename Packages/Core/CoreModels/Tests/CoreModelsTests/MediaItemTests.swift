//
//  MediaItemTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

import Testing
@testable import CoreModels

@Suite("MediaItem generalization")
struct MediaItemTests {
    @Test("mediaType defaults to .movie so existing movie call sites are unchanged")
    func defaultsToMovie() {
        let item = MediaItem(id: 1, title: "Fight Club", overview: "…")
        #expect(item.mediaType == .movie)
    }

    @Test("the Movie alias resolves to MediaItem")
    func movieAliasIsMediaItem() {
        let movie: Movie = MediaItem(id: 1, title: "A", overview: "")
        #expect(movie == MediaItem(id: 1, title: "A", overview: ""))
    }

    @Test("a TV item can be constructed with the same entity")
    func tvItem() {
        let show = MediaItem(id: 2, mediaType: .tv, title: "Severance", overview: "…")
        #expect(show.mediaType == .tv)
        #expect(show.title == "Severance")
    }

    @Test("mediaType participates in equality — same id, different kind are distinct")
    func mediaTypeAffectsEquality() {
        let asMovie = MediaItem(id: 3, mediaType: .movie, title: "X", overview: "")
        let asTV = MediaItem(id: 3, mediaType: .tv, title: "X", overview: "")
        #expect(asMovie != asTV)
        #expect(asMovie.hashValue != asTV.hashValue || asMovie != asTV)
    }

    @Test("MediaKind is exhaustive over movie and tv")
    func mediaKindCases() {
        #expect(MediaKind.allCases == [.movie, .tv])
    }
}
