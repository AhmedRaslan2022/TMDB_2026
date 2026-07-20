//
//  SettingsStore.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

import CoreModels

/// The persisted app preferences the Settings screen reads and writes — a port
/// this feature owns. The composition root adapts it to `UserDefaults` plus the
/// caches (features never reach the storage layer directly). A reference type
/// so a write is visible to the app root that applies the theme.
@MainActor
public protocol SettingsStore: AnyObject {
    var theme: AppTheme { get set }
    var language: AppLanguage { get set }
    /// Clears the image cache and any cached API data.
    func clearCache() async
}
