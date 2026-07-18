//
//  MovieDTOMapperTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 18/07/2026.
//

import CoreModels
import Foundation
import Testing
@testable import FeatureHome

@Suite("MovieDTO mapping")
struct MovieDTOMapperTests {
    private func makeDTO(
        releaseDate: String? = "1999-10-15",
        overview: String? = "An insomniac office worker…",
        voteAverage: Double? = 8.4,
        voteCount: Int? = 30000,
        genreIds: [Int]? = [18, 53]
    ) -> MovieDTO {
        MovieDTO(
            id: 550,
            title: "Fight Club",
            overview: overview,
            posterPath: "/poster.jpg",
            backdropPath: "/backdrop.jpg",
            releaseDate: releaseDate,
            voteAverage: voteAverage,
            voteCount: voteCount,
            genreIds: genreIds
        )
    }

    @Test("maps every field, parsing the yyyy-MM-dd release date as UTC")
    func fullMapping() {
        let movie = makeDTO().toDomain()

        #expect(movie.id == 550)
        #expect(movie.title == "Fight Club")
        #expect(movie.overview == "An insomniac office worker…")
        #expect(movie.posterPath == "/poster.jpg")
        #expect(movie.backdropPath == "/backdrop.jpg")
        #expect(movie.voteAverage == 8.4)
        #expect(movie.voteCount == 30000)
        #expect(movie.genreIDs == [18, 53])
        var components = DateComponents(year: 1999, month: 10, day: 15)
        components.timeZone = TimeZone(identifier: "UTC")
        #expect(movie.releaseDate == Calendar(identifier: .gregorian).date(from: components))
    }

    @Test("missing optionals fall back instead of failing", arguments: [nil, ""])
    func lenientDefaults(releaseDate: String?) {
        let movie = makeDTO(
            releaseDate: releaseDate,
            overview: nil,
            voteAverage: nil,
            voteCount: nil,
            genreIds: nil
        ).toDomain()

        #expect(movie.releaseDate == nil)
        #expect(movie.overview.isEmpty)
        #expect(movie.voteAverage == 0)
        #expect(movie.voteCount == 0)
        #expect(movie.genreIDs.isEmpty)
    }

    @Test("an unparseable release date becomes nil, not a failure")
    func garbageDateIsNil() {
        #expect(makeDTO(releaseDate: "next Tuesday").toDomain().releaseDate == nil)
    }

    @Test("page mapping carries pagination and maps every result")
    func pageMapping() {
        let dto = MoviePageDTO(page: 2, results: [makeDTO(), makeDTO()], totalPages: 5)

        let page = dto.toDomain()

        #expect(page.page == 2)
        #expect(page.movies.count == 2)
        #expect(page.totalPages == 5)
        #expect(page.hasMorePages)
    }

    @Test("the last page reports no more pages")
    func lastPage() {
        let page = MoviePageDTO(page: 5, results: [], totalPages: 5).toDomain()

        #expect(!page.hasMorePages)
    }
}
