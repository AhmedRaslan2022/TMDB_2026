import Observation

/// The four root tabs of the main shell.
enum AppTab: Hashable, CaseIterable {
    case home
    case search
    case favorites
    case profile
}

/// Root coordinator. Owns the auth-gate switch and the selected tab; child
/// coordinators own per-tab navigation. Views never mutate navigation state
/// directly — they call coordinator methods.
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

    /// Called when auth completes (real session handling lands in Sprint 2).
    func completeAuthGate() {
        rootScene = .main
    }

    /// Returns to the auth gate, e.g. after logout.
    func signOut() {
        rootScene = .auth
        selectedTab = .home
    }
}
