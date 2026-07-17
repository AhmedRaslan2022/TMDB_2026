//
//  SwiftDataUserStore.swift
//  TMDB
//
//  Created by Ahmed Raslan on 17/07/2026.
//

import FeatureAuth
import SwiftData
import SwiftDataStorage

/// `UserScopedDataStore` over SwiftData. Deletes the models tied to the
/// signed-in user on logout. `CachedMovie` is intentionally left: it's a
/// non-user-scoped content cache, refreshed on next fetch.
@MainActor
struct SwiftDataUserStore: UserScopedDataStore {
    let modelContainer: ModelContainer

    func clearAll() async throws {
        let context = modelContainer.mainContext
        // Batch deletes are not atomic across models: if the second throws,
        // the first may already be applied. Acceptable for a logout wipe —
        // the data is being discarded and the error still propagates.
        try context.delete(model: FavoriteMovie.self)
        try context.delete(model: RecentSearch.self)
        if context.hasChanges {
            try context.save()
        }
    }
}
