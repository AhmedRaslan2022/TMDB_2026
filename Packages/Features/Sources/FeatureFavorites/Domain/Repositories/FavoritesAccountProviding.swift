//
//  FavoritesAccountProviding.swift
//  TMDB
//
//  Created by Ahmed Raslan on 19/07/2026.
//

/// Resolves the account favorites sync should reconcile against. Implemented
/// in the composition root from the persisted session; returns `nil` for
/// guest / logged-out users, or until the account ID is known (Profile task
/// 5.1 populates it — sync stays a safe no-op until then).
public protocol FavoritesAccountProviding: Sendable {
    func currentAccount() async -> FavoritesAccount?
}
