//
//  AppRatingSessionProvider.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

import FeatureMovieDetails
import KeychainStorage

/// Resolves the TMDB session id for rating writes from the persisted
/// credentials. Returns `nil` for logged-out users, at which point a rating
/// write fails fast so the details screen rolls its optimistic star back.
struct AppRatingSessionProvider: MovieRatingSessionProviding {
    let secureStorage: any SecureStorage

    func sessionID() async -> String? {
        try? await secureStorage.string(for: .sessionID)
    }
}
