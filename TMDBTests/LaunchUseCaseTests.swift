//
//  LaunchUseCaseTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 26/07/2026.
//

import Testing
@testable import TMDB

@MainActor
@Suite("LaunchUseCase")
struct LaunchUseCaseTests {
    private func destination(onboarded: Bool, session: Bool) async -> LaunchDestination {
        let useCase = LaunchUseCaseImpl(
            hasCompletedOnboarding: { onboarded },
            hasSession: { session }
        )
        return await useCase.execute()
    }

    @Test("first launch (not onboarded) → onboarding, regardless of session")
    func firstLaunchShowsOnboarding() async {
        #expect(await destination(onboarded: false, session: false) == .onboarding)
        #expect(await destination(onboarded: false, session: true) == .onboarding)
    }

    @Test("onboarded with a persisted session → main shell")
    func onboardedWithSessionEntersMain() async {
        #expect(await destination(onboarded: true, session: true) == .main)
    }

    @Test("onboarded without a session → auth gate")
    func onboardedWithoutSessionShowsAuth() async {
        #expect(await destination(onboarded: true, session: false) == .authGate)
    }
}
