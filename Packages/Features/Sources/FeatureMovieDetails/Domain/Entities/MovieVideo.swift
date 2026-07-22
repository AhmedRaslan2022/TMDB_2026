//
//  MovieVideo.swift
//  TMDB
//
//  Created by Ahmed Raslan on 19/07/2026.
//

/// A promotional video attached to a movie. `key` is resolved against the
/// hosting site by the presentation layer (e.g. a YouTube watch URL).
public struct MovieVideo: Hashable, Sendable, Identifiable {
    /// Hosting sites TMDB serves; the raw value matches the API string.
    public enum Site: String, Sendable {
        case youTube = "YouTube"
        case vimeo = "Vimeo"
    }

    public let id: String
    public let name: String
    public let key: String
    public let site: Site
    /// TMDB's video kind, e.g. `"Trailer"`, `"Teaser"`, `"Clip"`.
    public let type: String
    public let isOfficial: Bool

    public init(id: String, name: String, key: String, site: Site, type: String, isOfficial: Bool = false) {
        self.id = id
        self.name = name
        self.key = key
        self.site = site
        self.type = type
        self.isOfficial = isOfficial
    }

    /// `true` for full trailers, the kind the details screen surfaces first.
    public var isTrailer: Bool {
        type == "Trailer"
    }

    /// `true` for teasers — the fallback when a movie has no full trailer.
    public var isTeaser: Bool {
        type == "Teaser"
    }
}
