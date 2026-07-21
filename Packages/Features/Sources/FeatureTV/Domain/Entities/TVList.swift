//
//  TVList.swift
//  TMDB
//
//  Created by Ahmed Raslan on 21/07/2026.
//

/// The TV lists the feature can fetch — the TV twin of `MovieList`, driving a
/// single parameterized use case instead of one clone per list.
public enum TVList: Hashable, Sendable, CaseIterable {
    case onTheAir
    case popular
    case topRated
}
