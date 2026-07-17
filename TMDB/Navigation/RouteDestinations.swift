import FeatureFavorites
import FeatureHome
import FeatureMovieDetails
import FeatureProfile
import FeatureSearch
import SwiftUI

/// Route → view mapping for every feature. This is the only place feature
/// routes are resolved to concrete screens, which is what lets features stay
/// ignorant of each other (e.g. Home pushing MovieDetails).
enum RouteDestinations {
    /// Attaches every feature's `navigationDestination` mapping to a tab's
    /// `NavigationStack` content.
    @MainActor
    static func attach(to view: some View) -> some View {
        view
            .navigationDestination(for: HomeRoute.self) { route in
                switch route {
                case let .movieDetails(movieID):
                    MovieDetailsPlaceholderView(movieID: movieID)
                }
            }
            .navigationDestination(for: SearchRoute.self) { route in
                switch route {
                case let .movieDetails(movieID):
                    MovieDetailsPlaceholderView(movieID: movieID)
                }
            }
            .navigationDestination(for: FavoritesRoute.self) { route in
                switch route {
                case let .movieDetails(movieID):
                    MovieDetailsPlaceholderView(movieID: movieID)
                }
            }
            .navigationDestination(for: ProfileRoute.self) { route in
                switch route {
                case .settings:
                    SettingsPlaceholderView()
                }
            }
    }
}
