//
//  TrendingWindow.swift
//  TMDB
//
//  Created by Ahmed Raslan on 18/07/2026.
//

/// Time window for TMDB trending lists.
public enum TrendingWindow: String, CaseIterable, Hashable, Sendable {
    case day
    case week
}
