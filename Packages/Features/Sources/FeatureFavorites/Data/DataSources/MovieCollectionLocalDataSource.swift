//
//  MovieCollectionLocalDataSource.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

import CoreModels
import Foundation
import SwiftData
import SwiftDataStorage

/// Local persistence for a saved-movie collection. Internal; the store
/// consumes it.
protocol MovieCollectionLocalDataSource: Sendable {
    /// Entries most-recently-added first.
    func all() async throws -> [Movie]
    func contains(movieID: Int) async throws -> Bool
    /// Adds `movie`, or refreshes its title/poster if already stored; the
    /// original `addedAt` is preserved so re-adding doesn't reorder it.
    func upsert(_ movie: Movie) async throws
    func remove(movieID: Int) async throws
}

/// One generic SwiftData source for ANY `CollectionMovieModel` — favorites and
/// watchlist reuse it by specializing `Model`. `@MainActor` with a dedicated
/// `ModelContext(container)` (not `mainContext`, which traps on the macOS host
/// test runner); matching is fetch-and-filter in Swift, avoiding host-fragile
/// `#Predicate`.
@MainActor
final class MovieCollectionLocalDataSourceImpl<Model: CollectionMovieModel>: MovieCollectionLocalDataSource {
    private let context: ModelContext

    init(modelContainer: ModelContainer) {
        context = ModelContext(modelContainer)
    }

    func all() async throws -> [Movie] {
        try fetchAll().map { Movie(id: $0.movieID, title: $0.title, overview: "", posterPath: $0.posterPath) }
    }

    func contains(movieID: Int) async throws -> Bool {
        try fetchAll().contains { $0.movieID == movieID }
    }

    func upsert(_ movie: Movie) async throws {
        if let existing = try fetchAll().first(where: { $0.movieID == movie.id }) {
            existing.title = movie.title
            existing.posterPath = movie.posterPath
        } else {
            context.insert(Model(movieID: movie.id, title: movie.title, posterPath: movie.posterPath, addedAt: .now))
        }
        try context.save()
    }

    func remove(movieID: Int) async throws {
        for match in try fetchAll() where match.movieID == movieID {
            context.delete(match)
        }
        try context.save()
    }

    private func fetchAll() throws -> [Model] {
        try context.fetch(FetchDescriptor<Model>(sortBy: [SortDescriptor(\.addedAt, order: .reverse)]))
    }
}
