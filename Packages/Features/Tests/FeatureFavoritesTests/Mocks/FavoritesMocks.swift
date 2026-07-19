//
//  FavoritesMocks.swift
//  TMDB
//
//  Created by Ahmed Raslan on 19/07/2026.
//

import CoreModels
@testable import FeatureFavorites

func favoriteTestMovie(_ id: Int) -> Movie {
    Movie(id: id, title: "Movie \(id)", overview: "")
}

/// In-memory local source — most-recent-first, no SwiftData.
@MainActor
final class FavoritesLocalMock: FavoritesLocalDataSource {
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

/// Records pushes and serves stubbed remote pages.
@MainActor
final class FavoritesRemoteMock: FavoritesRemoteDataSource {
    var pages: [Int: MoviePage] = [:]
    var favoritesError: Error?
    var setFavoriteError: Error?
    private(set) var pushed: [(movieID: Int, isFavorite: Bool)] = []
    private(set) var requestedPages: [Int] = []

    func favorites(account _: FavoritesAccount, page: Int) async throws -> MoviePage {
        requestedPages.append(page)
        if let favoritesError {
            throw favoritesError
        }
        return pages[page] ?? MoviePage(page: page, movies: [], totalPages: page)
    }

    func setFavorite(account _: FavoritesAccount, movieID: Int, isFavorite: Bool) async throws {
        if let setFavoriteError {
            throw setFavoriteError
        }
        pushed.append((movieID, isFavorite))
    }

    /// Stubs one page of favorites.
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
