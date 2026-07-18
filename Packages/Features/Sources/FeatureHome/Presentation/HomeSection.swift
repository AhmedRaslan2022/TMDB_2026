//
//  HomeSection.swift
//  TMDB
//
//  Created by Ahmed Raslan on 18/07/2026.
//

import CoreModels

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
