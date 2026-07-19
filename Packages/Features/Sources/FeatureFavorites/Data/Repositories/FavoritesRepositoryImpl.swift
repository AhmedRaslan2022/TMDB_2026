//
//  FavoritesRepositoryImpl.swift
//  TMDB
//
//  Created by Ahmed Raslan on 19/07/2026.
//

import CoreModels
import CoreUtilities
import Networking
import SwiftData

/// Offline-first `FavoritesRepository`: the SwiftData local store is the
/// source of truth, so favorites work fully offline and for guest sessions.
/// When an account is available it also pushes toggles to TMDB and reconciles
/// the two lists on `synchronize()`.
///
/// The account is resolved lazily through `FavoritesAccountProviding`, which
/// returns `nil` until Profile (task 5.1) populates the account ID — so the
/// remote paths are inert (safe no-ops) until then, and all local behavior
/// works today.
@MainActor
public struct FavoritesRepositoryImpl: FavoritesRepository {
    /// Guards a pathological remote list from looping forever.
    private static let maxSyncPages = 500

    private let local: any FavoritesLocalDataSource
    private let remote: any FavoritesRemoteDataSource
    private let accountProvider: any FavoritesAccountProviding
    private let logger = AppLogger(category: "Favorites")

    /// Composition-root entry point: wires the SwiftData local source and the
    /// TMDB remote source.
    public init(
        modelContainer: ModelContainer,
        apiClient: any APIClient,
        accountProvider: any FavoritesAccountProviding
    ) {
        self.init(
            local: FavoritesLocalDataSourceImpl(modelContainer: modelContainer),
            remote: FavoritesRemoteDataSourceImpl(apiClient: apiClient),
            accountProvider: accountProvider
        )
    }

    init(
        local: any FavoritesLocalDataSource,
        remote: any FavoritesRemoteDataSource,
        accountProvider: any FavoritesAccountProviding
    ) {
        self.local = local
        self.remote = remote
        self.accountProvider = accountProvider
    }

    public func favorites() async throws -> [Movie] {
        try await local.all()
    }

    public func isFavorite(movieID: Int) async throws -> Bool {
        try await local.contains(movieID: movieID)
    }

    public func setFavorite(_ movie: Movie, isFavorite: Bool) async throws {
        // Local first — always applied, so the toggle succeeds offline.
        if isFavorite {
            try await local.upsert(movie)
        } else {
            try await local.remove(movieID: movie.id)
        }
        // Remote push is best-effort: a failure (offline, hiccup) leaves the
        // lists divergent, which the next `synchronize()` heals — losing a
        // favorite to a network blip would be worse than eventual consistency.
        guard let account = await accountProvider.currentAccount() else { return }
        do {
            try await remote.setFavorite(account: account, movieID: movie.id, isFavorite: isFavorite)
        } catch {
            logger.warning("favorite push failed for \(movie.id): \(error)")
        }
    }

    /// Union merge: remote favorites missing locally are added; local
    /// favorites missing remotely are pushed up. Without tombstones this
    /// favors keeping favorites over propagating removals — an acceptable
    /// trade for a portfolio app, and documented as such.
    public func synchronize() async throws {
        guard let account = await accountProvider.currentAccount() else { return }

        let remoteMovies = try await pullAllRemote(account: account)
        let localMovies = try await local.all()
        let localIDs = Set(localMovies.map(\.id))
        let remoteIDs = Set(remoteMovies.map(\.id))

        for movie in remoteMovies where !localIDs.contains(movie.id) {
            try await local.upsert(movie)
        }
        for movie in localMovies where !remoteIDs.contains(movie.id) {
            try await remote.setFavorite(account: account, movieID: movie.id, isFavorite: true)
        }
    }

    private func pullAllRemote(account: FavoritesAccount) async throws -> [Movie] {
        var movies: [Movie] = []
        var page = 1
        while page <= Self.maxSyncPages {
            let result = try await remote.favorites(account: account, page: page)
            movies += result.movies
            guard result.hasMorePages else { return movies }
            page += 1
        }
        logger.warning("favorites sync hit the \(Self.maxSyncPages)-page cap; list truncated")
        return movies
    }
}
