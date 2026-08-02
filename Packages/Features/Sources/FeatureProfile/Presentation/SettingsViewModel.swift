//
//  SettingsViewModel.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

import CoreModels
import Observation

/// Drives the Settings screen: appearance/language preferences persisted
/// through the injected `SettingsStore`, plus cache-clear and sign-out actions.
///
/// Mirrors the store's values into observable state at init and writes back on
/// selection. This is the sole writer of the store's theme/language, so the two
/// can't desync; if another feature ever mutates the store directly, this would
/// need to re-read on appear.
@Observable
@MainActor
public final class SettingsViewModel {
    public private(set) var theme: AppTheme
    public private(set) var language: AppLanguage
    public private(set) var appIcon: AppIcon
    /// True while a cache clear is in progress (disables the button).
    public private(set) var isClearingCache = false
    /// True once a cache clear has completed, for a confirmation affordance.
    public private(set) var didClearCache = false
    /// Whether the current session is a full TMDB account. `nil` until
    /// `loadAccountState()` resolves; guest and signed-out are both `false`,
    /// so the account row offers "Sign In" instead of "Sign Out".
    public private(set) var isAuthenticated: Bool?

    private let store: any SettingsStore
    private let onSignOut: () -> Void
    private let isAuthenticatedProvider: @MainActor () async -> Bool

    public init(
        store: any SettingsStore,
        onSignOut: @escaping () -> Void,
        isAuthenticated: @escaping @MainActor () async -> Bool
    ) {
        self.store = store
        self.onSignOut = onSignOut
        isAuthenticatedProvider = isAuthenticated
        theme = store.theme
        language = store.language
        appIcon = store.appIcon
    }

    /// Resolves the session kind for the account row. Called from the view's
    /// `.task`; idempotent, so a re-appear simply refreshes the answer.
    public func loadAccountState() async {
        isAuthenticated = await isAuthenticatedProvider()
    }

    public func selectTheme(_ theme: AppTheme) {
        guard theme != self.theme else { return }
        self.theme = theme
        store.theme = theme
    }

    public func selectLanguage(_ language: AppLanguage) {
        guard language != self.language else { return }
        self.language = language
        store.language = language
    }

    public func selectIcon(_ appIcon: AppIcon) {
        guard appIcon != self.appIcon else { return }
        self.appIcon = appIcon
        store.appIcon = appIcon
    }

    public func clearCache() async {
        guard !isClearingCache else { return }
        isClearingCache = true
        didClearCache = false
        await store.clearCache()
        isClearingCache = false
        didClearCache = true
    }

    public func signOut() {
        onSignOut()
    }
}
