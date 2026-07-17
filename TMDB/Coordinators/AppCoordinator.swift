//
//  AppCoordinator.swift
//  TMDB
//
//  Created by Ahmed Raslan on 17/07/2026.
//

import CoreUtilities
import FeatureAuth
import FeatureFavorites
import FeatureHome
import FeatureProfile
import FeatureSearch
import Observation

/// The four root tabs of the main shell.
enum AppTab: Hashable, CaseIterable {
    case home
    case search
    case favorites
    case profile
}

/// Root coordinator. Owns the auth-gate switch, the selected tab, and one
/// child coordinator per tab; children own per-tab navigation. Views never
/// mutate navigation state directly — they call coordinator methods.
@Observable
@MainActor
final class AppCoordinator {
    /// Which root scene is on screen.
    enum RootScene {
        /// Login / guest entry. Shown until a session exists.
        case auth
        /// The authenticated (or guest) tab shell.
        case main
    }

    /// Modals presented as sheets. All modal presentation is
    /// coordinator-driven — views only report intent.
    enum Sheet: String, Identifiable {
        /// App/about information (placeholder until Sprint 5's settings).
        case about

        var id: String {
            rawValue
        }
    }

    /// Modals presented as full-screen covers.
    enum FullScreenCover: String, Identifiable {
        /// What's-new walkthrough (placeholder content for now).
        case whatsNew

        var id: String {
            rawValue
        }
    }

    private(set) var rootScene: RootScene = .auth
    var selectedTab: AppTab = .home
    var presentedSheet: Sheet?
    var presentedFullScreenCover: FullScreenCover?

    let home = TabCoordinator<HomeRoute>()
    let search = TabCoordinator<SearchRoute>()
    let favorites = TabCoordinator<FavoritesRoute>()
    let profile = TabCoordinator<ProfileRoute>()

    private let auth: AuthModule
    private let logger = AppLogger(category: "Auth")

    init(auth: AuthModule) {
        self.auth = auth
    }

    /// Builds the auth-gate view model, wiring a completed session back to the
    /// root switch. The session itself is already persisted by the use case.
    func makeAuthViewModel() -> AuthViewModel {
        auth.makeAuthViewModel(onAuthenticated: { [weak self] _ in
            self?.completeAuthGate()
        })
    }

    /// Restores a persisted session on launch, entering the main shell
    /// directly when one exists. Called once from the root view.
    func restoreSession() async {
        if await auth.hasPersistedSession() {
            rootScene = .main
        }
    }

    /// Called when auth completes; enters the main shell.
    func completeAuthGate() {
        rootScene = .main
    }

    func presentSheet(_ sheet: Sheet) {
        presentedSheet = sheet
    }

    func presentFullScreenCover(_ cover: FullScreenCover) {
        presentedFullScreenCover = cover
    }

    func dismissModal() {
        presentedSheet = nil
        presentedFullScreenCover = nil
    }

    /// Returns to the auth gate, e.g. after logout, resetting all tab and
    /// modal state. Navigation resets immediately; session teardown (remote
    /// delete + keychain wipe) runs in the background — the local wipe happens
    /// first inside the use case, so the next launch cannot restore it.
    func signOut() {
        rootScene = .auth
        selectedTab = .home
        dismissModal()
        home.popToRoot()
        search.popToRoot()
        favorites.popToRoot()
        profile.popToRoot()
        Task {
            do {
                try await auth.logOut()
            } catch {
                logger.error("Logout teardown failed: \(error)")
            }
        }
    }
}
