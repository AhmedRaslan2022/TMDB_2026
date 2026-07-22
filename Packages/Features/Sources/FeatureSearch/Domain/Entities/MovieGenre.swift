//
//  MovieGenre.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

/// A TMDB movie genre, used to build the Discover filter's genre picker.
public struct MovieGenre: Sendable, Hashable, Identifiable {
    public let id: Int
    public let name: String

    public init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
}
