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

    private(set) var rootScene: RootScene = .auth
    var selectedTab: AppTab = .home

    let home = TabCoordinator<HomeRoute>()
    let search = TabCoordinator<SearchRoute>()
    let favorites = TabCoordinator<FavoritesRoute>()
    let profile = TabCoordinator<ProfileRoute>()

    /// Called when auth completes (real session handling lands in Sprint 2).
    func completeAuthGate() {
        rootScene = .main
    }

    /// Returns to the auth gate, e.g. after logout, resetting all tab state.
    func signOut() {
        rootScene = .auth
        selectedTab = .home
        home.popToRoot()
        search.popToRoot()
        favorites.popToRoot()
        profile.popToRoot()
    }
}
