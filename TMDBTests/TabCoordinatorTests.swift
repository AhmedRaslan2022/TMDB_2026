// By Ahmed Raslan ®

import FeatureHome
import FeatureProfile
import Testing
@testable import TMDB

@MainActor
struct TabCoordinatorTests {
    @Test func startsWithEmptyPath() {
        let coordinator = TabCoordinator<HomeRoute>()

        #expect(coordinator.path.isEmpty)
    }

    @Test func pushAppendsRoute() {
        let coordinator = TabCoordinator<HomeRoute>()

        coordinator.push(.movieDetails(movieID: 550))
        coordinator.push(.movieDetails(movieID: 551))

        #expect(coordinator.path == [.movieDetails(movieID: 550), .movieDetails(movieID: 551)])
    }

    @Test func popRemovesLastRoute() {
        let coordinator = TabCoordinator<HomeRoute>()
        coordinator.push(.movieDetails(movieID: 550))
        coordinator.push(.movieDetails(movieID: 551))

        coordinator.pop()

        #expect(coordinator.path == [.movieDetails(movieID: 550)])
    }

    @Test func popOnEmptyPathIsHarmless() {
        let coordinator = TabCoordinator<HomeRoute>()

        coordinator.pop()

        #expect(coordinator.path.isEmpty)
    }

    @Test func popToRootClearsPath() {
        let coordinator = TabCoordinator<HomeRoute>()
        coordinator.push(.movieDetails(movieID: 550))
        coordinator.push(.movieDetails(movieID: 551))

        coordinator.popToRoot()

        #expect(coordinator.path.isEmpty)
    }

    @Test func signOutResetsChildCoordinators() {
        let app = AppCoordinator()
        app.completeAuthGate()
        app.home.push(.movieDetails(movieID: 550))
        app.profile.push(.settings)

        app.signOut()

        #expect(app.home.path.isEmpty)
        #expect(app.profile.path.isEmpty)
        #expect(app.rootScene == .auth)
    }
}
