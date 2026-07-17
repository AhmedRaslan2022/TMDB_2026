import Foundation
import SwiftData
import Testing
@testable import CoreStorage

/// All suites use in-memory containers — no test touches disk.
@MainActor
struct ModelContainerFactoryTests {
    @Test func makesInMemoryContainerWithFullSchema() throws {
        let container = try ModelContainerFactory.make(inMemory: true)

        let entityNames = container.schema.entities.map(\.name).sorted()
        #expect(entityNames == ["CachedMovie", "FavoriteMovie", "RecentSearch"])
        let allInMemory = container.configurations.allSatisfy(\.isStoredInMemoryOnly)
        #expect(allInMemory)
    }

    @Test func favoriteMovieRoundtrip() throws {
        let container = try ModelContainerFactory.make(inMemory: true)
        let context = container.mainContext

        context.insert(FavoriteMovie(movieID: 550, title: "Fight Club", posterPath: "/poster.jpg"))
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<FavoriteMovie>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.movieID == 550)
        #expect(fetched.first?.title == "Fight Club")
    }

    @Test func recentSearchRoundtripAndDelete() throws {
        let container = try ModelContainerFactory.make(inMemory: true)
        let context = container.mainContext

        let search = RecentSearch(query: "dune")
        context.insert(search)
        try context.save()
        #expect(try context.fetchCount(FetchDescriptor<RecentSearch>()) == 1)

        context.delete(search)
        try context.save()
        #expect(try context.fetchCount(FetchDescriptor<RecentSearch>()) == 0)
    }

    @Test func cachedMovieStoresAllFields() throws {
        let container = try ModelContainerFactory.make(inMemory: true)
        let context = container.mainContext
        let release = Date(timeIntervalSince1970: 941_414_400)

        context.insert(CachedMovie(
            movieID: 550,
            title: "Fight Club",
            overview: "An insomniac office worker…",
            posterPath: "/poster.jpg",
            backdropPath: "/backdrop.jpg",
            releaseDate: release,
            voteAverage: 8.4
        ))
        try context.save()

        let movie = try #require(try context.fetch(FetchDescriptor<CachedMovie>()).first)
        #expect(movie.overview.hasPrefix("An insomniac"))
        #expect(movie.backdropPath == "/backdrop.jpg")
        #expect(movie.releaseDate == release)
        #expect(movie.voteAverage == 8.4)
    }

    @Test func uniqueMovieIDUpserts() throws {
        let container = try ModelContainerFactory.make(inMemory: true)
        let context = container.mainContext

        context.insert(FavoriteMovie(movieID: 550, title: "Fight Club"))
        try context.save()
        context.insert(FavoriteMovie(movieID: 550, title: "Fight Club (updated)"))
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<FavoriteMovie>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.title == "Fight Club (updated)")
    }
}
