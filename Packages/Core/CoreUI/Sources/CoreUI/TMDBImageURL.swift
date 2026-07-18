//
//  TMDBImageURL.swift
//  TMDB
//
//  Created by Ahmed Raslan on 18/07/2026.
//

import Foundation

/// Composes TMDB image URLs from the environment's image base (e.g. `…/t/p`)
/// and an API-provided image path. Shared by every feature that renders
/// posters or backdrops; the base URL is injected from the composition root.
public enum TMDBImageURL {
    /// TMDB image size buckets the app uses.
    public enum Size: String, Sendable {
        /// Small poster: dense grids.
        case w185
        /// Carousel/grid poster.
        case w342
        /// Large poster / small backdrop.
        case w500
        /// Detail-screen backdrops.
        case w780
        /// Full-size original.
        case original
    }

    /// The image URL, or `nil` when `path` is absent.
    /// - Parameter path: TMDB image path as served (`/abc.jpg`).
    public static func url(base: URL, path: String?, size: Size) -> URL? {
        guard let path else { return nil }
        return base
            .appending(path: size.rawValue)
            .appending(path: String(path.drop(while: { $0 == "/" })))
    }
}
