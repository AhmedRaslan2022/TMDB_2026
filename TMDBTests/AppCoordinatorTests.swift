//
//  AppCoordinatorTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 17/07/2026.
//

import Testing
@testable import TMDB

@MainActor
struct AppCoordinatorTests {
    @Test("launch begins under the splash — isLaunching until start resolves")
    func startsLaunchingUnderSplash() {
        let coordinator = AppCoordinator(auth: .stub)

        #expect(coordinator.isLaunching)
        #expect(coordinator.selectedTab == .home)
    }

    @Test func completingOnboardingShowsAuthGate() {
        let coordinator = AppCoordinator(auth: .stub)

        coordinator.completeOnboarding()

        #expect(coordinator.rootScene == .auth)
    }

    @Test("start routes to the launch use case's destination and drops the splash")
    func startRoutesToDestination() async {
        for (destination, expected) in [
            (LaunchDestination.onboarding, AppCoordinator.RootScene.onboarding),
            (.authGate, .auth),
            (.main, .main),
        ] {
            let coordinator = AppCoordinator(auth: .stub)

            await coordinator.start(using: StubLaunchUseCase(destination: destination), minimumSplashDuration: .zero)

            #expect(coordinator.rootScene == expected)
            #expect(!coordinator.isLaunching, "the splash dismisses once the destination is applied")
        }
    }

    @Test func completingAuthGateShowsMainShell() {
        let coordinator = AppCoordinator(auth: .stub)

        coordinator.completeAuthGate()

        #expect(coordinator.rootScene == .main)
    }

    @Test func signOutReturnsToAuthAndResetsTab() {
        let coordinator = AppCoordinator(auth: .stub)
        coordinator.completeAuthGate()
        coordinator.selectedTab = .favorites

        coordinator.signOut()

        #expect(coordinator.rootScene == .auth)
        #expect(coordinator.selectedTab == .home)
    }

    @Test func selectedTabIsMutable() {
        let coordinator = AppCoordinator(auth: .stub)

        coordinator.selectedTab = .search

        #expect(coordinator.selectedTab == .search)
    }
}

private struct StubLaunchUseCase: LaunchUseCase {
    let destination: LaunchDestination
    func execute() async -> LaunchDestination {
        destination
    }
}
