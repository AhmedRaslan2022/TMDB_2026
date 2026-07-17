//
//  ModelContainerFactory.swift
//  TMDB
//
//  Created by Ahmed Raslan on 17/07/2026.
//

import SwiftData

/// Builds the app's `ModelContainer` with the full schema.
///
/// Per-environment isolation comes for free from the per-env bundle IDs
/// (each app variant has its own sandbox); tests and the Test environment
/// use the in-memory variant so nothing touches disk.
public enum ModelContainerFactory {
    /// Every `@Model` type the app persists. New models must be added here.
    public static let schema = Schema([
        FavoriteMovie.self,
        RecentSearch.self,
        CachedMovie.self,
    ])

    /// - Parameter inMemory: `true` for tests and the Test environment.
    public static func make(inMemory: Bool = false) throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
