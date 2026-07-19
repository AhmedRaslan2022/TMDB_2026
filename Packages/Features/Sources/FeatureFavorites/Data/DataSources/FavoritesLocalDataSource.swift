//
//  FavoritesLocalDataSource.swift
//  TMDB
//
//  Created by Ahmed Raslan on 19/07/2026.
//

import CoreModels
import Foundation
import SwiftData
import SwiftDataStorage

/// Local favorites persistence over SwiftData's `FavoriteMovie` @Model.
/// Internal to the Data layer; the repository consumes it.
protocol FavoritesLocalDataSource: Sendable {
    /// Favorites most-recently-added first.
    func all() async throws -> [Movie]
    func contains(movieID: Int) async throws -> Bool
    /// Adds `movie`, or refreshes its title/poster if already stored. The
    /// original `addedAt` is preserved so re-favoriting doesn't reorder it.
    func upsert(_ movie: Movie) async throws
    func remove(movieID: Int) async throws
}

/// `@MainActor`-confined with a dedicated `ModelContext(container)` — NOT
/// `container.mainContext`, which traps under the macOS host test runner (see
/// the recent-searches store for the same reasoning). Matching is done by
/// fetch-and-filter in Swift, avoiding host-fragile `#Predicate`; the set is
/// small (a user's favorites).
@MainActor
final class FavoritesLocalDataSourceImpl: FavoritesLocalDataSource {
    private let context: ModelContext

    init(modelContainer: ModelContainer) {
        context = ModelContext(modelContainer)
    }

    func all() async throws -> [Movie] {
        try fetchAll().map(\.asMovie)
    }

    func contains(movieID: Int) async throws -> Bool {
        try fetchAll().contains { $0.movieID == movieID }
    }

    func upsert(_ movie: Movie) async throws {
        if let existing = try fetchAll().first(where: { $0.movieID == movie.id }) {
            existing.title = movie.title
            existing.posterPath = movie.posterPath
        } else {
            context.insert(FavoriteMovie(movieID: movie.id, title: movie.title, posterPath: movie.posterPath))
        }
        try context.save()
    }

    func remove(movieID: Int) async throws {
        for match in try fetchAll() where match.movieID == movieID {
            context.delete(match)
        }
        try context.save()
    }

    private func fetchAll() throws -> [FavoriteMovie] {
        try context.fetch(FetchDescriptor<FavoriteMovie>(
            sortBy: [SortDescriptor(\.addedAt, order: .reverse)]
        ))
    }
}

private extension FavoriteMovie {
    /// Maps the stored favorite to the shared domain entity. Only poster and
    /// title are persisted, so the richer fields carry defaults — enough for
    /// a favorites grid.
    var asMovie: Movie {
        Movie(id: movieID, title: title, overview: "", posterPath: posterPath)
    }
}
