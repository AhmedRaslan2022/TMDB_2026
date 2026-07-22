//
//  TMDBImageURLTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 18/07/2026.
//

import Foundation
import Testing
@testable import CoreUI

@Suite("TMDBImageURL")
struct TMDBImageURLTests {
    private let base: URL

    init() throws {
        base = try #require(URL(string: "https://image.tmdb.org/t/p"))
    }

    @Test("composes size and path against the base")
    func composition() {
        let url = TMDBImageURL.url(base: base, path: "/poster.jpg", size: .w342)

        #expect(url?.absoluteString == "https://image.tmdb.org/t/p/w342/poster.jpg")
    }

    @Test("nil path yields nil")
    func nilPath() {
        #expect(TMDBImageURL.url(base: base, path: nil, size: .w342) == nil)
    }

    @Test("a path without a leading slash composes identically")
    func noLeadingSlash() {
        let url = TMDBImageURL.url(base: base, path: "poster.jpg", size: .w780)

        #expect(url?.absoluteString == "https://image.tmdb.org/t/p/w780/poster.jpg")
    }
}
