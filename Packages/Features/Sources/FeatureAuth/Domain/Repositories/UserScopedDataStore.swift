//
//  UserScopedDataStore.swift
//  TMDB
//
//  Created by Ahmed Raslan on 17/07/2026.
//

/// Abstraction over the app's user-scoped local data (favorites, recent
/// searches, …) so `LogoutUseCase` can wipe it on sign-out without knowing
/// the concrete `@Model` types — those live in other features. Implemented
/// in the composition root over SwiftData (task 2.6).
public protocol UserScopedDataStore: Sendable {
    /// Deletes every piece of local data tied to the signed-in user.
    func clearAll() async throws
}
