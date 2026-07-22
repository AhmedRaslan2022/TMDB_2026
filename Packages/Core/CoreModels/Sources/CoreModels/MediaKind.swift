//
//  MediaKind.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

/// The kind of catalog entry a `MediaItem` represents. Lets one generic entity,
/// use case, and grid serve both movies and TV shows (Sprint 6) instead of
/// duplicating the pipeline per media type.
public enum MediaKind: String, Sendable, Hashable, CaseIterable, Identifiable {
    case movie
    case tv

    public var id: String {
        rawValue
    }
}
