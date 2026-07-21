//
//  DeepLinkParserTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 21/07/2026.
//

import Foundation
import Testing
@testable import TMDB

/// URL → `DeepLink` translation (task 7.7). Pure parsing, no UI.
struct DeepLinkParserTests {
    private func parse(_ string: String) -> DeepLink? {
        guard let url = URL(string: string) else { return nil }
        return DeepLinkParser.parse(url)
    }

    @Test("recognized links map to their destinations", arguments: [
        ("tmdbapp://movie/550", DeepLink.movie(id: 550)),
        ("tmdbapp://tv/1396", DeepLink.tvShow(id: 1396)),
        ("tmdbapp://person/287", DeepLink.person(id: 287)),
        ("tmdbapp://tv", DeepLink.tab(.tv)),
        ("tmdbapp://home", DeepLink.tab(.home)),
        ("tmdbapp://favorites", DeepLink.tab(.favorites)),
        ("tmdbapp://profile", DeepLink.tab(.profile)),
        ("tmdbapp://search", DeepLink.search(query: nil)),
        ("tmdbapp://search?q=dune", DeepLink.search(query: "dune")),
    ])
    func recognizedLinks(input: String, expected: DeepLink) {
        #expect(parse(input) == expected)
    }

    @Test("host casing is ignored")
    func hostCaseInsensitive() {
        #expect(parse("TMDBAPP://Movie/550") == .movie(id: 550))
    }

    @Test("an empty search query resolves to nil, not an empty string")
    func emptySearchQuery() {
        #expect(parse("tmdbapp://search?q=") == .search(query: nil))
    }

    @Test("unrecognized or malformed links return nil", arguments: [
        "https://example.com/movie/550", // wrong scheme
        "tmdbapp://movie", // missing id
        "tmdbapp://movie/abc", // non-numeric id
        "tmdbapp://movie/0", // non-positive id
        "tmdbapp://movie/-5",
        "tmdbapp://unknown/1", // unknown host
        "tmdbapp://",
    ])
    func rejectedLinks(input: String) {
        #expect(parse(input) == nil)
    }
}
