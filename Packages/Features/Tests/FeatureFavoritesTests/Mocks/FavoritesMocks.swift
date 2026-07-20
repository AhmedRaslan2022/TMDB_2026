//
//  FavoritesMocks.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

import CoreModels
@testable import FeatureFavorites

func favoriteTestMovie(_ id: Int) -> Movie {
    Movie(id: id, title: "Movie \(id)", overview: "")
}

/// In-memory local source — most-recent-first, no SwiftData.
@MainActor
final class CollectionLocalMock: MovieCollectionLocalDataSource {
    private(set) var movies: [Movie] = []
    private(set) var upserted: [Movie] = []
    private(set) var removed: [Int] = []

    func all() async throws -> [Movie] {
        movies
    }

    func contains(movieID: Int) async throws -> Bool {
        movies.contains { $0.id == movieID }
    }

    func upsert(_ movie: Movie) async throws {
        upserted.append(movie)
        movies.removeAll { $0.id == movie.id }
        movies.insert(movie, at: 0)
    }

    func remove(movieID: Int) async throws {
        removed.append(movieID)
        movies.removeAll { $0.id == movieID }
    }

    func seed(_ ids: [Int]) {
        movies = ids.map(favoriteTestMovie)
    }
}

/// A recorded membership push.
struct CollectionPush: Equatable {
    let collection: MovieCollection
    let movieID: Int
    let isMember: Bool
}

/// Records pushes/collection and serves stubbed remote pages.
@MainActor
final class CollectionRemoteMock: MovieCollectionRemoteDataSource {
    var pages: [Int: MoviePage] = [:]
    var listError: Error?
    var setError: Error?
    private(set) var pushed: [CollectionPush] = []
    private(set) var requestedPages: [Int] = []

    func list(collection _: MovieCollection, account _: FavoritesAccount, page: Int) async throws -> MoviePage {
        requestedPages.append(page)
        if let listError {
            throw listError
        }
        return pages[page] ?? MoviePage(page: page, movies: [], totalPages: page)
    }

    func setMembership(collection: MovieCollection, account _: FavoritesAccount, movieID: Int, isMember: Bool) async throws {
        if let setError {
            throw setError
        }
        pushed.append(CollectionPush(collection: collection, movieID: movieID, isMember: isMember))
    }

    func stubPage(_ page: Int, ids: [Int], totalPages: Int) {
        pages[page] = MoviePage(page: page, movies: ids.map(favoriteTestMovie), totalPages: totalPages)
    }
}

@MainActor
final class FavoritesAccountProviderMock: FavoritesAccountProviding {
    var account: FavoritesAccount?

    init(account: FavoritesAccount? = nil) {
        self.account = account
    }

    func currentAccount() async -> FavoritesAccount? {
        account
    }
}

extension FavoritesAccount {
    static let testAccount = FavoritesAccount(accountID: 42, sessionID: "sess")
}

/// In-memory `FavoritesRepository` for favorites view-model tests.
@MainActor
final class FavoritesRepositoryMock: FavoritesRepository {
    var movies: [Movie] = []
    var favoritesError: Error?
    private(set) var syncCount = 0
    private(set) var setCalls: [(movieID: Int, isFavorite: Bool)] = []

    func favorites() async throws -> [Movie] {
        if let favoritesError {
            throw favoritesError
        }
        return movies
    }

    func isFavorite(movieID: Int) async throws -> Bool {
        movies.contains { $0.id == movieID }
    }

    func setFavorite(_ movie: Movie, isFavorite: Bool) async throws {
        setCalls.append((movie.id, isFavorite))
        movies.removeAll { $0.id == movie.id }
        if isFavorite {
            movies.insert(movie, at: 0)
        }
    }

    func synchronize() async throws {
        syncCount += 1
    }

    func seed(_ ids: [Int]) {
        movies = ids.map(favoriteTestMovie)
    }
}
