//
//  ModalPresentationTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 17/07/2026.
//

import Testing
@testable import TMDB

@MainActor
struct ModalPresentationTests {
    @Test func startsWithNoModal() {
        let coordinator = AppCoordinator(auth: .stub)

        #expect(coordinator.presentedSheet == nil)
        #expect(coordinator.presentedFullScreenCover == nil)
    }

    @Test func presentsAndDismissesSheet() {
        let coordinator = AppCoordinator(auth: .stub)

        coordinator.presentSheet(.about)
        #expect(coordinator.presentedSheet == .about)

        coordinator.dismissModal()
        #expect(coordinator.presentedSheet == nil)
    }

    @Test func presentsAndDismissesFullScreenCover() {
        let coordinator = AppCoordinator(auth: .stub)

        coordinator.presentFullScreenCover(.whatsNew)
        #expect(coordinator.presentedFullScreenCover == .whatsNew)

        coordinator.dismissModal()
        #expect(coordinator.presentedFullScreenCover == nil)
    }

    @Test func signOutDismissesModals() {
        let coordinator = AppCoordinator(auth: .stub)
        coordinator.completeAuthGate()
        coordinator.presentSheet(.about)

        coordinator.signOut()

        #expect(coordinator.presentedSheet == nil)
        #expect(coordinator.presentedFullScreenCover == nil)
    }
}
