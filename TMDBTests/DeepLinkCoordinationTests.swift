//
//  DeepLinkCoordinationTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 21/07/2026.
//

import FeatureHome
import FeatureTV
import Foundation
import Testing
@testable import TMDB

/// The coordinator turning a `DeepLink` into a tab selection + navigation stack
/// (task 7.1), including cold-start deferral.
@MainActor
struct DeepLinkCoordinationTests {
    private func mainCoordinator() -> AppCoordinator {
        let coordinator = AppCoordinator(auth: .stub)
        coordinator.completeAuthGate() // enter the main shell
        return coordinator
    }

    @Test("a movie link selects Home and pushes movie details on a clean stack")
    func movieLink() {
        let coordinator = mainCoordinator()
        coordinator.selectedTab = .profile
        coordinator.home.push(.movieDetails(movieID: 1)) // stale entry

        coordinator.handle(.movie(id: 550))

        #expect(coordinator.selectedTab == .home)
        #expect(coordinator.home.path == [.movieDetails(movieID: 550)], "stack reset then pushed")
    }

    @Test("a TV link selects the TV tab and pushes show details")
    func tvLink() {
        let coordinator = mainCoordinator()

        coordinator.handle(.tvShow(id: 1396))

        #expect(coordinator.selectedTab == .tv)
        #expect(coordinator.tv.path == [.showDetails(showID: 1396)])
    }

    @Test("a person link selects Home and pushes person details")
    func personLink() {
        let coordinator = mainCoordinator()

        coordinator.handle(.person(id: 287))

        #expect(coordinator.selectedTab == .home)
        #expect(coordinator.home.path == [.person(personID: 287)])
    }

    @Test("a bare tab link just selects the tab")
    func tabLink() {
        let coordinator = mainCoordinator()

        coordinator.handle(.tab(.favorites))

        #expect(coordinator.selectedTab == .favorites)
    }

    @Test("handle(url:) parses and applies, reporting whether it was recognized")
    func handleURL() throws {
        let coordinator = mainCoordinator()

        let handled = try coordinator.handle(url: #require(URL(string: "tmdbapp://movie/700")))
        let ignored = try coordinator.handle(url: #require(URL(string: "https://example.com")))

        #expect(handled)
        #expect(ignored == false)
        #expect(coordinator.home.path == [.movieDetails(movieID: 700)])
    }

    @Test("a cold-start link at the auth gate is deferred, then applied when the shell appears")
    func coldStartDeferral() {
        let coordinator = AppCoordinator(auth: .stub) // still at the auth gate

        coordinator.handle(.movie(id: 550))
        #expect(coordinator.home.path.isEmpty, "nothing navigates while gated")
        #expect(coordinator.selectedTab == .home)

        coordinator.completeAuthGate()

        #expect(coordinator.selectedTab == .home)
        #expect(coordinator.home.path == [.movieDetails(movieID: 550)], "the deferred link lands after auth")
    }

    @Test("a deep link dismisses any presented modal for a clean landing")
    func dismissesModal() {
        let coordinator = mainCoordinator()
        coordinator.presentSheet(.about)

        coordinator.handle(.tvShow(id: 1))

        #expect(coordinator.presentedSheet == nil)
    }
}
