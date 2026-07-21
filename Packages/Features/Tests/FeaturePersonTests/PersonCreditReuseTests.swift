//
//  PersonCreditReuseTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 21/07/2026.
//

import CoreModels
import Testing
@testable import FeaturePerson

/// Reuse-safety (task 6.6): a person's filmography mixes movie and TV credits
/// in ONE `[MediaItem]`-backed collection, so `PersonCredit` identity must
/// survive a movie and a TV title sharing the same TMDB id.
@Suite("PersonCredit reuse safety")
struct PersonCreditReuseTests {
    @Test("a movie and TV credit with the same underlying id get distinct credit ids")
    func compositeIdDisambiguatesKinds() {
        let movie = PersonCredit(media: MediaItem(id: 550, mediaType: .movie, title: "M", overview: ""))
        let tv = PersonCredit(media: MediaItem(id: 550, mediaType: .tv, title: "S", overview: ""))

        #expect(movie.id != tv.id, "kind-qualified id prevents a ForEach collision in a mixed filmography")
        #expect(movie.id == "movie.550")
        #expect(tv.id == "tv.550")
    }

    @Test("filmography carries both kinds through one collection")
    func mixedFilmography() {
        let credits = [
            PersonCredit(media: MediaItem(id: 1, mediaType: .movie, title: "M", overview: "")),
            PersonCredit(media: MediaItem(id: 1, mediaType: .tv, title: "S", overview: "")),
        ]
        let bundle = PersonDetailsBundle(person: Person(id: 9, name: "A", biography: ""), filmography: credits)

        #expect(Set(bundle.filmography.map(\.id)).count == 2, "no id collision across the two kinds")
        #expect(bundle.filmography.map(\.media.mediaType) == [.movie, .tv])
    }
}
