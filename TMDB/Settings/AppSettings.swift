//
//  AppSettings.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

import CoreModels
import CoreUI
import FeatureProfile
import Foundation
import SwiftData
import SwiftDataStorage
import UserDefaultsStorage

/// The app-wide preference store: the single source of truth for theme and
/// content language, persisted to `UserDefaults`. Adapts the composition root's
/// storage + caches to `FeatureProfile`'s `SettingsStore` port, and is observed
/// by the app root to apply the theme.
@Observable
@MainActor
final class AppSettings: SettingsStore {
    var theme: AppTheme {
        didSet { defaults.set(theme.rawValue, for: .appTheme) }
    }

    var language: AppLanguage {
        didSet {
            defaults.set(language.rawValue, for: .appLanguage)
            languageBox.code = language.rawValue
        }
    }

    @ObservationIgnored private let defaults: any DefaultsStorage
    @ObservationIgnored private let imageCache: ImageCache
    @ObservationIgnored private let modelContainer: ModelContainer
    @ObservationIgnored private let languageBox = LanguageBox()

    init(defaults: any DefaultsStorage, imageCache: ImageCache, modelContainer: ModelContainer) {
        self.defaults = defaults
        self.imageCache = imageCache
        self.modelContainer = modelContainer
        theme = defaults.string(for: .appTheme).flatMap(AppTheme.init) ?? .system
        // First launch has no stored choice → seed from the device language
        // (task 8.3), so an Arabic device gets Arabic content out of the box.
        let language = defaults.string(for: .appLanguage).flatMap(AppLanguage.init)
            ?? .matching(languageCode: Locale.current.language.languageCode?.identifier)
        self.language = language
        languageBox.code = language.rawValue // didSet doesn't fire during init
    }

    /// A thread-safe provider of the current language code for the API
    /// interceptor, which runs off the main actor. Reflects later changes.
    nonisolated var languageCodeProvider: @Sendable () -> String {
        { [languageBox] in languageBox.code }
    }

    /// The device's region (ISO 3166-1) for TMDB's `region` param — release
    /// dates and availability reflect where the user is. Read per request off
    /// the main actor; `Locale.current` is thread-safe.
    nonisolated var regionCodeProvider: @Sendable () -> String? {
        { Locale.current.region?.identifier }
    }

    func clearCache() async {
        await imageCache.clearMemory()
        try? await imageCache.clearDisk()
        // Cached movie summaries are pure cache — safe to drop. Favorites,
        // watchlist, and recent searches are user data and are left intact.
        let context = ModelContext(modelContainer)
        try? context.delete(model: CachedMovie.self)
        try? context.save()
    }
}

/// A lock-guarded language code, so the off-main API interceptor can read the
/// current value that the main-actor `AppSettings` writes.
private final class LanguageBox: @unchecked Sendable {
    private let lock = NSLock()
    private var _code = AppLanguage.english.rawValue

    var code: String {
        get { lock.withLock { _code } }
        set { lock.withLock { _code = newValue } }
    }
}
