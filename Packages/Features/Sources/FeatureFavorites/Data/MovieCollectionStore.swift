//
//  MovieCollectionStore.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

import CoreModels
import CoreUtilities

/// The shared, offline-first engine behind every saved-movie collection. Both
/// the favorites and watchlist repositories are thin wrappers over this — the
/// sync, push, and merge logic is written exactly once here (task 5.3's reuse).
///
/// Local store is the source of truth (works offline / for guests). When an
/// account is available it also pushes toggles and reconciles on `synchronize`.
@MainActor
struct MovieCollectionStore {
    /// Guards a pathological remote list from looping forever.
    private static let maxSyncPages = 500

    let collection: MovieCollection
    private let local: any MovieCollectionLocalDataSource
    private let remote: any MovieCollectionRemoteDataSource
    private let accountProvider: any FavoritesAccountProviding
    private let logger = AppLogger(category: "Collections")

    init(
        collection: MovieCollection,
        local: any MovieCollectionLocalDataSource,
        remote: any MovieCollectionRemoteDataSource,
        accountProvider: any FavoritesAccountProviding
    ) {
        self.collection = collection
        self.local = local
        self.remote = remote
        self.accountProvider = accountProvider
    }

    func movies() async throws -> [Movie] {
        try await local.all()
    }

    func contains(movieID: Int) async throws -> Bool {
        try await local.contains(movieID: movieID)
    }

    func setMembership(_ movie: Movie, isMember: Bool) async throws {
        // Local first — always applied, so the toggle succeeds offline.
        if isMember {
            try await local.upsert(movie)
        } else {
            try await local.remove(movieID: movie.id)
        }
        // Remote push is best-effort: a failure leaves the lists divergent,
        // which the next `synchronize()` heals — losing an entry to a network
        // blip would be worse than eventual consistency.
        guard let account = await accountProvider.currentAccount() else { return }
        do {
            try await remote.setMembership(collection: collection, account: account, movieID: movie.id, isMember: isMember)
        } catch {
            logger.warning("\(collection.rawValue) push failed for \(movie.id): \(error)")
        }
    }

    /// Union merge: remote-only entries are added locally; local-only entries
    /// are pushed up. Without tombstones this favors keeping entries over
    /// propagating removals — an accepted trade for a portfolio app.
    func synchronize() async throws {
        guard let account = await accountProvider.currentAccount() else { return }

        let remoteMovies = try await pullAllRemote(account: account)
        let localMovies = try await local.all()
        let localIDs = Set(localMovies.map(\.id))
        let remoteIDs = Set(remoteMovies.map(\.id))

        for movie in remoteMovies where !localIDs.contains(movie.id) {
            try await local.upsert(movie)
        }
        for movie in localMovies where !remoteIDs.contains(movie.id) {
            try await remote.setMembership(collection: collection, account: account, movieID: movie.id, isMember: true)
        }
    }

    private func pullAllRemote(account: FavoritesAccount) async throws -> [Movie] {
        var movies: [Movie] = []
        var page = 1
        while page <= Self.maxSyncPages {
            let result = try await remote.list(collection: collection, account: account, page: page)
            movies += result.movies
            guard result.hasMorePages else { return movies }
            page += 1
        }
        logger.warning("\(collection.rawValue) sync hit the \(Self.maxSyncPages)-page cap; list truncated")
        return movies
    }
}
