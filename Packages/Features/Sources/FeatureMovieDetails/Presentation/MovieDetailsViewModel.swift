//
//  MovieDetailsViewModel.swift
//  TMDB
//
//  Created by Ahmed Raslan on 19/07/2026.
//

import CoreModels
import CoreUI
import Foundation
import Observation

/// Drives the movie details screen: one bundle fetch, plus the URL
/// composition views need (backdrop, profiles, posters, trailers).
@Observable
@MainActor
public final class MovieDetailsViewModel {
    /// Exhaustive screen state.
    public enum ViewState: Equatable {
        case idle
        case loading
        case loaded(MovieDetailsBundle)
        case error(LocalizedStringResource)
    }

    public private(set) var state: ViewState = .idle
    /// Whether this movie is favorited. Optimistically updated by `toggleFavorite`.
    public private(set) var isFavorite = false
    /// Whether this movie is on the watchlist. Optimistically updated by `toggleWatchlist`.
    public private(set) var isOnWatchlist = false
    /// The user's rating (0.5–10), or `nil` when unrated. Optimistically updated
    /// by `rate`/`clearRating`.
    public private(set) var userRating: Double?

    public let movieID: Int
    private let fetchDetails: any FetchMovieDetailsUseCase
    private let favorites: any FavoriteToggling
    private let watchlist: any WatchlistToggling
    private let rating: any MovieRatingRepository
    private let imageBaseURL: URL

    public init(
        movieID: Int,
        fetchDetails: any FetchMovieDetailsUseCase,
        favorites: any FavoriteToggling,
        watchlist: any WatchlistToggling,
        rating: any MovieRatingRepository,
        imageBaseURL: URL
    ) {
        self.movieID = movieID
        self.fetchDetails = fetchDetails
        self.favorites = favorites
        self.watchlist = watchlist
        self.rating = rating
        self.imageBaseURL = imageBaseURL
    }

    /// Loads the bundle. Idempotent once loaded; callable from error (retry).
    public func load() async {
        switch state {
        case .loading, .loaded:
            return
        case .idle, .error:
            break
        }
        state = .loading
        do {
            let bundle = try await fetchDetails.execute(movieID: movieID)
            // Read membership before publishing so the toolbar icons never
            // flash empty for an already-saved movie.
            isFavorite = await favorites.isFavorite(movieID: movieID)
            isOnWatchlist = await watchlist.isOnWatchlist(movieID: movieID)
            // A rating read failure shouldn't block the screen — fall back to
            // unrated. `try?` flattens the optional, so no double-optional here.
            userRating = try? await rating.rating(movieID: movieID)
            state = .loaded(bundle)
        } catch is CancellationError {
            state = .idle
        } catch {
            state = .error(LocalizedStringResource(
                "details.error",
                defaultValue: "Couldn't load this movie.",
                comment: "Shown when the movie details fetch fails"
            ))
        }
    }

    /// Flips the favorite state immediately, then persists it — rolling the UI
    /// back if the write fails. No-op until the details bundle is loaded.
    public func toggleFavorite() async {
        guard let movie = loadedMovie else { return }
        let target = !isFavorite
        isFavorite = target
        do {
            try await favorites.setFavorite(movie, isFavorite: target)
        } catch {
            // Roll back only if a newer tap hasn't already moved past `target`.
            if isFavorite == target {
                isFavorite = !target
            }
        }
    }

    /// Watchlist twin of `toggleFavorite`: optimistic flip + rollback.
    public func toggleWatchlist() async {
        guard let movie = loadedMovie else { return }
        let target = !isOnWatchlist
        isOnWatchlist = target
        do {
            try await watchlist.setOnWatchlist(movie, isOnWatchlist: target)
        } catch {
            if isOnWatchlist == target {
                isOnWatchlist = !target
            }
        }
    }

    /// Sets the user's rating, updating the stars immediately and rolling back
    /// if the write fails. No-op until the details bundle is loaded.
    public func rate(_ value: Double) async {
        await applyRating(value)
    }

    /// Clears the user's rating (optimistic + rollback). No-op if unrated or
    /// before the bundle loads.
    public func clearRating() async {
        guard userRating != nil else { return }
        await applyRating(nil)
    }

    private func applyRating(_ value: Double?) async {
        guard isLoaded else { return }
        let previous = userRating
        userRating = value
        do {
            try await rating.setRating(value, movieID: movieID)
        } catch {
            // Roll back only if a newer change hasn't already moved past `value`.
            if userRating == value {
                userRating = previous
            }
        }
    }

    private var isLoaded: Bool {
        if case .loaded = state {
            true
        } else {
            false
        }
    }

    /// The loaded movie as a `Movie`, or nil before the bundle loads.
    private var loadedMovie: Movie? {
        guard case let .loaded(bundle) = state else { return nil }
        return Movie(
            id: bundle.details.id,
            title: bundle.details.title,
            overview: bundle.details.overview,
            posterPath: bundle.details.posterPath
        )
    }

    // MARK: Image / link URLs

    /// The w780 backdrop for the stretchy header (poster as fallback).
    public func backdropURL(for details: MovieDetails) -> URL? {
        TMDBImageURL.url(base: imageBaseURL, path: details.backdropPath ?? details.posterPath, size: .w780)
    }

    /// The w185 headshot for cast cards.
    public func profileURL(for member: CastMember) -> URL? {
        TMDBImageURL.url(base: imageBaseURL, path: member.profilePath, size: .w185)
    }

    /// The w342 poster for similar/recommendation cards.
    public func posterURL(for movie: Movie) -> URL? {
        TMDBImageURL.url(base: imageBaseURL, path: movie.posterPath, size: .w342)
    }

    /// Trailers first-class: official ones lead. Falls back to teasers when
    /// a movie has no full trailer.
    public func featuredVideos(in bundle: MovieDetailsBundle) -> [MovieVideo] {
        let trailers = bundle.videos.filter(\.isTrailer)
        let pool = trailers.isEmpty ? bundle.videos.filter(\.isTeaser) : trailers
        return pool.sorted { $0.isOfficial && !$1.isOfficial }
    }

    /// Where the video plays, per hosting site.
    public func watchURL(for video: MovieVideo) -> URL? {
        switch video.site {
        case .youTube: URL(string: "https://www.youtube.com/watch?v=\(video.key)")
        case .vimeo: URL(string: "https://vimeo.com/\(video.key)")
        }
    }

    /// A thumbnail for the trailer card (YouTube only; Vimeo needs an API).
    public func thumbnailURL(for video: MovieVideo) -> URL? {
        guard video.site == .youTube else { return nil }
        return URL(string: "https://img.youtube.com/vi/\(video.key)/hqdefault.jpg")
    }
}
