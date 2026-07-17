import Observation

/// Navigation state for one tab: a typed path bound to that tab's
/// `NavigationStack`. Views request navigation through coordinator methods —
/// never by mutating navigation state themselves.
@Observable
@MainActor
final class TabCoordinator<Route: Hashable> {
    var path = [Route]()

    /// Explicit deinit works around a swift-frontend 6.3 optimizer crash
    /// (EarlyPerfInliner on the generated deinit of a generic @Observable
    /// class) that only reproduces under -O (Staging/Live configs).
    deinit {}

    func push(_ route: Route) {
        path.append(route)
    }

    func pop() {
        _ = path.popLast()
    }

    func popToRoot() {
        path.removeAll()
    }
}
