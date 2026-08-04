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
import FeatureTV
import Foundation
import Observation

/// The five root tabs of the main shell.
///
/// `nonisolated` for the same reason as `DeepLink`, which carries one as a
/// payload: a pure value type's `Hashable` conformance must not be main-actor
/// isolated, or nonisolated code (and the deep-link tests) can't compare tabs.
nonisolated enum AppTab: Hashable, CaseIterable {
    case home
    case tv
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
    /// Which root scene is on screen underneath the splash. The splash itself
    /// is not a scene: it is ALWAYS mounted as the root layer on launch (see
    /// `isLaunching` and `RootView`), and simply fades out over whichever
    /// scene the launch decision picked.
    enum RootScene {
        /// First-launch interactive onboarding.
        case onboarding
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
    /// True from app start until the launch decision resolves. The root view
    /// keeps the splash mounted on top of everything while this is true, so
    /// the splash is unconditionally the first thing on screen — never a
    /// routing option that could be skipped.
    private(set) var isLaunching = true
    var selectedTab: AppTab = .home
    var presentedSheet: Sheet?
    var presentedFullScreenCover: FullScreenCover?
    /// A deep link received before the main shell was ready (e.g. a cold-start
    /// link arriving at the auth gate). Applied once the shell appears, so the
    /// link still lands on the right screen with a correct back stack.
    private var pendingDeepLink: DeepLink?

    let home = TabCoordinator<HomeRoute>()
    let tv = TabCoordinator<TVRoute>()
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

    /// Resolves the launch destination (onboarding / auth / main) via the
    /// launch use case, switches the root scene underneath the splash, then
    /// dismisses the splash. Called once from the root view. The splash is
    /// held on screen for at least `minimumSplashDuration` so an instant
    /// decision doesn't reduce it to a flicker.
    func start(using launch: any LaunchUseCase, minimumSplashDuration: Duration = .milliseconds(700)) async {
        let started = ContinuousClock.now
        let destination = await launch.execute()
        let remaining = minimumSplashDuration - started.duration(to: .now)
        if remaining > .zero {
            try? await Task.sleep(for: remaining)
        }
        switch destination {
        case .onboarding:
            rootScene = .onboarding
        case .authGate:
            rootScene = .auth
        case .main:
            rootScene = .main
            applyPendingDeepLink()
        }
        isLaunching = false
    }

    /// Restores a persisted session, entering the main shell when one exists
    /// and otherwise showing the auth gate. Retained as the explicit
    /// "restore" path (the launch use case decides the wider first-run flow).
    func restoreSession() async {
        if await auth.hasPersistedSession() {
            rootScene = .main
            applyPendingDeepLink()
        } else {
            rootScene = .auth
        }
    }

    /// Called when onboarding finishes; a fresh install has no session yet, so
    /// present the auth gate. Persisting the "seen" flag is the app's job (via
    /// the `OnboardingCompletion` port).
    func completeOnboarding() {
        rootScene = .auth
    }

    /// Called when auth completes; enters the main shell.
    func completeAuthGate() {
        rootScene = .main
        applyPendingDeepLink()
    }

    // MARK: Deep linking

    /// Entry point for an incoming URL (custom scheme or universal link).
    /// Returns whether the URL was a recognized deep link.
    @discardableResult
    func handle(url: URL) -> Bool {
        guard let deepLink = DeepLinkParser.parse(url) else { return false }
        handle(deepLink)
        return true
    }

    /// Applies a deep link: on the main shell it selects the tab and rebuilds
    /// that tab's stack immediately; at the auth gate it's deferred until the
    /// shell appears (cold start).
    func handle(_ deepLink: DeepLink) {
        guard rootScene == .main else {
            pendingDeepLink = deepLink
            return
        }
        dismissModal()
        switch deepLink {
        case let .movie(id):
            selectedTab = .home
            home.popToRoot()
            home.push(.movieDetails(movieID: id))
        case let .tvShow(id):
            selectedTab = .tv
            tv.popToRoot()
            tv.push(.showDetails(showID: id))
        case let .person(id):
            selectedTab = .home
            home.popToRoot()
            home.push(.person(personID: id))
        case .search:
            selectedTab = .search
            search.popToRoot()
        case let .tab(tab):
            selectedTab = tab
        }
    }

    /// Applies and clears any link deferred while at the auth gate.
    private func applyPendingDeepLink() {
        guard let deepLink = pendingDeepLink else { return }
        pendingDeepLink = nil
        handle(deepLink)
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
    /// modal state. Navigation resets immediately; session teardown (local
    /// wipe first, then remote delete) runs in the background via the auth
    /// module's barrier, so a new login/guest attempt waits for it and can
    /// never be clobbered by the wipe.
    func signOut() {
        rootScene = .auth
        selectedTab = .home
        dismissModal()
        home.popToRoot()
        tv.popToRoot()
        search.popToRoot()
        favorites.popToRoot()
        profile.popToRoot()
        auth.beginLogout { [logger] error in
            logger.error("Logout teardown failed: \(error)")
        }
    }
}
