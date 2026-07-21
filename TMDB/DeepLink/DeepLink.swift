//
//  DeepLink.swift
//  TMDB
//
//  Created by Ahmed Raslan on 21/07/2026.
//

import Foundation

/// A resolved deep-link destination — the app-level intent a `tmdbapp://` URL
/// (or, later, a universal link) translates to. The coordinator turns one of
/// these into a tab selection + navigation stack; keeping it a pure value makes
/// the URL-parsing layer fully unit-testable without any UI.
enum DeepLink: Equatable {
    case movie(id: Int)
    case tvShow(id: Int)
    case person(id: Int)
    /// Search tab, optionally pre-seeded with a query.
    case search(query: String?)
    /// A bare tab selection (home / tv / favorites / profile).
    case tab(AppTab)
}

/// Translates incoming URLs into a `DeepLink`. Pure and side-effect free so the
/// mapping is exhaustively unit-tested (task 7.7).
enum DeepLinkParser {
    /// The custom scheme registered in Info.plist (`CFBundleURLTypes`).
    static let scheme = "tmdbapp"

    /// Parses a `tmdbapp://…` URL, or `nil` if it isn't a recognized link.
    ///
    /// Grammar (host-based, so both `tmdbapp://movie/123` and the equivalent
    /// components resolve): `movie/<id>`, `tv/<id>`, `person/<id>`, `search`
    /// (`?q=` optional), and the bare tabs `home` / `tv` / `favorites` /
    /// `profile`.
    static func parse(_ url: URL) -> DeepLink? {
        guard url.scheme?.lowercased() == scheme,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let host = components.host?.lowercased()
        else { return nil }

        // Path segments after the host, e.g. host="movie", segments=["123"].
        let segments = components.path.split(separator: "/").map(String.init)

        switch host {
        case "movie":
            return id(from: segments).map(DeepLink.movie)
        case "tv":
            // `tv/<id>` → a show; bare `tv` → the TV tab.
            if let id = id(from: segments) {
                return .tvShow(id: id)
            }
            return .tab(.tv)
        case "person":
            return id(from: segments).map(DeepLink.person)
        case "search":
            let query = components.queryItems?.first { $0.name == "q" }?.value
            return .search(query: query?.isEmpty == true ? nil : query)
        case "home":
            return .tab(.home)
        case "favorites":
            return .tab(.favorites)
        case "profile":
            return .tab(.profile)
        default:
            return nil
        }
    }

    /// The first path segment as a positive TMDB id, if present and valid.
    private static func id(from segments: [String]) -> Int? {
        guard let first = segments.first, let value = Int(first), value > 0 else { return nil }
        return value
    }
}
