import Observation

/// Navigation state for one tab: a typed path bound to that tab's
/// `NavigationStack`. Views request navigation through coordinator methods —
/// never by mutating navigation state themselves.
@Observable
@MainActor
final class TabCoordinator<Route: Hashable> {
    var path = [Route]()

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
