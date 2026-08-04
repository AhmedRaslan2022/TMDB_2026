//
//  AppContainer+Launch.swift
//  TMDB
//
//  Created by Ahmed Raslan on 02/08/2026.
//

import FeatureOnboarding

// MARK: - Launch & onboarding

extension AppContainer {
    /// The launch decision (onboarding / auth / main). Reads the onboarding
    /// flag and the persisted session. In UI tests (offline stubs) onboarding
    /// is treated as complete so the existing flows reach the auth gate.
    var launchUseCase: any LaunchUseCase {
        #if DEBUG
            // Each branch is bound to the @Sendable type before the ternary
            // picks one: inferring the ternary first produces a plain
            // `() -> Bool` that then can't be converted without a data race.
            let stubbed: @MainActor @Sendable () -> Bool = { true }
            let real: @MainActor @Sendable () -> Bool = { [appSettings] in appSettings.hasCompletedOnboarding }
            let onboardingComplete = UITestStubs.isActive ? stubbed : real
        #else
            let onboardingComplete: @MainActor @Sendable () -> Bool = { [appSettings] in appSettings.hasCompletedOnboarding }
        #endif
        return LaunchUseCaseImpl(
            hasCompletedOnboarding: onboardingComplete,
            hasSession: { [authModule] in await authModule.hasPersistedSession() }
        )
    }

    /// Builds the onboarding screen's view model, wiring completion to persist
    /// the "seen" flag and advance the root scene past onboarding.
    func makeOnboardingViewModel() -> OnboardingViewModel {
        OnboardingViewModel(
            completion: OnboardingCompletionAdapter { [appSettings, coordinator] in
                appSettings.hasCompletedOnboarding = true
                coordinator.completeOnboarding()
            }
        )
    }
}

/// Adapts the feature's `OnboardingCompletion` port to a composition-root
/// closure (persist the flag + route), so the package never touches storage
/// or navigation.
private struct OnboardingCompletionAdapter: OnboardingCompletion {
    let onComplete: @MainActor @Sendable () -> Void
    func completeOnboarding() {
        onComplete()
    }
}
