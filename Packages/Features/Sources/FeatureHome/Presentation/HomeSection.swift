//
//  HomeSection.swift
//  TMDB
//
//  Created by Ahmed Raslan on 18/07/2026.
//

import CoreModels
import Foundation

/// The sections of the Home screen, in display order. Each maps to one
/// `MovieList`; trending additionally carries the user-selected window.
public enum HomeSection: CaseIterable, Hashable, Identifiable, Sendable {
    case trending
    case nowPlaying
    case popular
    case topRated
    case upcoming

    public var id: Self {
        self
    }

    /// User-facing section title.
    public var title: LocalizedStringResource {
        switch self {
        case .trending:
            LocalizedStringResource(
                moduleKey: "home.section.trending",
                defaultValue: "Trending",
                bundle: .module,
                comment: "Home section title"
            )
        case .nowPlaying:
            LocalizedStringResource(
                moduleKey: "home.section.nowPlaying",
                defaultValue: "Now Playing",
                bundle: .module,
                comment: "Home section title"
            )
        case .popular:
            LocalizedStringResource(
                moduleKey: "home.section.popular",
                defaultValue: "Popular",
                bundle: .module,
                comment: "Home section title"
            )
        case .topRated:
            LocalizedStringResource(
                moduleKey: "home.section.topRated",
                defaultValue: "Top Rated",
                bundle: .module,
                comment: "Home section title"
            )
        case .upcoming:
            LocalizedStringResource(
                moduleKey: "home.section.upcoming",
                defaultValue: "Upcoming",
                bundle: .module,
                comment: "Home section title"
            )
        }
    }

    /// The list this section fetches, given the current trending window.
    func list(window: TrendingWindow) -> MovieList {
        switch self {
        case .trending: .trending(window)
        case .nowPlaying: .nowPlaying
        case .popular: .popular
        case .topRated: .topRated
        case .upcoming: .upcoming
        }
    }
}
