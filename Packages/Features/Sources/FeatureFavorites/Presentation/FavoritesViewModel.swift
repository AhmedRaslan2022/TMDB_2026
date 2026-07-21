//
//  FavoritesViewModel.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

import CoreModels
import CoreUI
import Foundation
import Observation

/// Drives the Favorites tab. Offline-first: reads the local store instantly on
/// every appearance (so a favorite toggled on the details screen shows up),
/// and reconciles with the account in the background (a no-op until an account
/// is available).
@Observable
@MainActor
public final class FavoritesViewModel {
    /// Exhaustive screen state.
    public enum ViewState: Equatable {
        case loading
        case loaded([Movie])
        case empty
        case error(LocalizedStringResource)
    }

    public private(set) var state: ViewState = .loading

    private let repository: any FavoritesRepository
    private let imageBaseURL: URL
    /// One reconcile per screen lifetime; pull-to-refresh forces another.
    private var hasSynced = false

    public init(repository: any FavoritesRepository, imageBaseURL: URL) {
        self.repository = repository
        self.imageBaseURL = imageBaseURL
    }

    /// The w342 poster URL for grid cells, or `nil` without a poster.
    public func posterURL(for movie: Movie) -> URL? {
        TMDBImageURL.url(base: imageBaseURL, path: movie.posterPath, size: .w342)
    }

    /// Called from the view's `.task` on every appearance: shows local
    /// favorites immediately, then reconciles once.
    public func load() async {
        await reload()
        guard !hasSynced else { return }
        hasSynced = true
        await refresh()
    }

    /// Pull-to-refresh: reconcile with the account, then re-read local.
    public func refresh() async {
        try? await repository.synchronize()
        await reload()
    }

    /// Removes a movie from favorites and updates the list.
    public func remove(_ movie: Movie) async {
        try? await repository.setFavorite(movie, isFavorite: false)
        await reload()
    }

    private func reload() async {
        do {
            let movies = try await repository.favorites()
            state = movies.isEmpty ? .empty : .loaded(movies)
        } catch {
            state = .error(LocalizedStringResource(
                moduleKey:
                "favorites.error",
                defaultValue: "Couldn't load your favorites.",
                bundle: .module,
                comment: "Shown when the favorites list fails to load"
            ))
        }
    }
}
