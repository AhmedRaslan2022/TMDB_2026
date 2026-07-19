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

    public let movieID: Int
    private let fetchDetails: any FetchMovieDetailsUseCase
    private let imageBaseURL: URL

    public init(movieID: Int, fetchDetails: any FetchMovieDetailsUseCase, imageBaseURL: URL) {
        self.movieID = movieID
        self.fetchDetails = fetchDetails
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
            state = try await .loaded(fetchDetails.execute(movieID: movieID))
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
