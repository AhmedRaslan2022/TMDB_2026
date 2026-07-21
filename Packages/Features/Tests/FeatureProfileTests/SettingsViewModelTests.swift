//
//  SettingsViewModelTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

import CoreModels
import Testing
@testable import FeatureProfile

@MainActor
@Suite("SettingsViewModel")
struct SettingsViewModelTests {
    /// Records writes and cache clears the same way the app's store would.
    private final class SettingsStoreMock: SettingsStore {
        var theme: AppTheme
        var language: AppLanguage
        var appIcon: AppIcon = .default
        private(set) var clearCount = 0

        init(theme: AppTheme = .system, language: AppLanguage = .english) {
            self.theme = theme
            self.language = language
        }

        func clearCache() async {
            clearCount += 1
        }
    }

    @Test("initial state mirrors the store")
    func initialState() {
        let store = SettingsStoreMock(theme: .dark, language: .arabic)
        let viewModel = SettingsViewModel(store: store, onSignOut: {})

        #expect(viewModel.theme == .dark)
        #expect(viewModel.language == .arabic)
    }

    @Test("selecting a theme updates the VM and persists through the store")
    func selectTheme() {
        let store = SettingsStoreMock()
        let viewModel = SettingsViewModel(store: store, onSignOut: {})

        viewModel.selectTheme(.light)

        #expect(viewModel.theme == .light)
        #expect(store.theme == .light)
    }

    @Test("selecting a language updates the VM and persists through the store")
    func selectLanguage() {
        let store = SettingsStoreMock()
        let viewModel = SettingsViewModel(store: store, onSignOut: {})

        viewModel.selectLanguage(.arabic)

        #expect(viewModel.language == .arabic)
        #expect(store.language == .arabic)
    }

    @Test("selecting an app icon updates the VM and persists through the store")
    func selectAppIcon() {
        let store = SettingsStoreMock()
        let viewModel = SettingsViewModel(store: store, onSignOut: {})

        viewModel.selectIcon(.midnight)

        #expect(viewModel.appIcon == .midnight)
        #expect(store.appIcon == .midnight)
    }

    @Test("clearCache delegates to the store and flips the confirmation flag")
    func clearCache() async {
        let store = SettingsStoreMock()
        let viewModel = SettingsViewModel(store: store, onSignOut: {})

        await viewModel.clearCache()

        #expect(store.clearCount == 1)
        #expect(viewModel.didClearCache)
        #expect(viewModel.isClearingCache == false)
    }

    @Test("signOut invokes the injected callback")
    func signOut() {
        var signedOut = false
        let viewModel = SettingsViewModel(store: SettingsStoreMock(), onSignOut: { signedOut = true })

        viewModel.signOut()

        #expect(signedOut)
    }
}
