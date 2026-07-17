import Testing
@testable import TMDB

@MainActor
struct ModalPresentationTests {
    @Test func startsWithNoModal() {
        let coordinator = AppCoordinator()

        #expect(coordinator.presentedSheet == nil)
        #expect(coordinator.presentedFullScreenCover == nil)
    }

    @Test func presentsAndDismissesSheet() {
        let coordinator = AppCoordinator()

        coordinator.presentSheet(.about)
        #expect(coordinator.presentedSheet == .about)

        coordinator.dismissModal()
        #expect(coordinator.presentedSheet == nil)
    }

    @Test func presentsAndDismissesFullScreenCover() {
        let coordinator = AppCoordinator()

        coordinator.presentFullScreenCover(.whatsNew)
        #expect(coordinator.presentedFullScreenCover == .whatsNew)

        coordinator.dismissModal()
        #expect(coordinator.presentedFullScreenCover == nil)
    }

    @Test func signOutDismissesModals() {
        let coordinator = AppCoordinator()
        coordinator.completeAuthGate()
        coordinator.presentSheet(.about)

        coordinator.signOut()

        #expect(coordinator.presentedSheet == nil)
        #expect(coordinator.presentedFullScreenCover == nil)
    }
}
