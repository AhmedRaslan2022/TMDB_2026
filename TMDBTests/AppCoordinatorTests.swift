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
    @Test func startsAtAuthGateOnHomeTab() {
        let coordinator = AppCoordinator()

        #expect(coordinator.rootScene == .auth)
        #expect(coordinator.selectedTab == .home)
    }

    @Test func completingAuthGateShowsMainShell() {
        let coordinator = AppCoordinator()

        coordinator.completeAuthGate()

        #expect(coordinator.rootScene == .main)
    }

    @Test func signOutReturnsToAuthAndResetsTab() {
        let coordinator = AppCoordinator()
        coordinator.completeAuthGate()
        coordinator.selectedTab = .favorites

        coordinator.signOut()

        #expect(coordinator.rootScene == .auth)
        #expect(coordinator.selectedTab == .home)
    }

    @Test func selectedTabIsMutable() {
        let coordinator = AppCoordinator()

        coordinator.selectedTab = .search

        #expect(coordinator.selectedTab == .search)
    }
}
