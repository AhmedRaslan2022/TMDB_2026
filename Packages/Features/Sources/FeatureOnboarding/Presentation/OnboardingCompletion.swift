//
//  OnboardingCompletion.swift
//  TMDB
//
//  Created by Ahmed Raslan on 26/07/2026.
//

/// Port the app fulfills to record that onboarding finished. The feature owns
/// the flow but not the persistence — the composition root adapts this to the
/// app's preference store (so onboarding shows on first launch only). Keeping
/// it a port means the package never reaches the storage layer directly.
@MainActor
public protocol OnboardingCompletion {
    /// Called once the user finishes or skips onboarding.
    func completeOnboarding()
}
