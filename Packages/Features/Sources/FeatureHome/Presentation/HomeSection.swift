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
            LocalizedStringResource("home.section.trending", defaultValue: "Trending", comment: "Home section title")
        case .nowPlaying:
            LocalizedStringResource("home.section.nowPlaying", defaultValue: "Now Playing", comment: "Home section title")
        case .popular:
            LocalizedStringResource("home.section.popular", defaultValue: "Popular", comment: "Home section title")
        case .topRated:
            LocalizedStringResource("home.section.topRated", defaultValue: "Top Rated", comment: "Home section title")
        case .upcoming:
            LocalizedStringResource("home.section.upcoming", defaultValue: "Upcoming", comment: "Home section title")
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
