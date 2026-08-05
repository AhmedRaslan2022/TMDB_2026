//
//  LaunchUseCase.swift
//  TMDB
//
//  Created by Ahmed Raslan on 26/07/2026.
//

/// Where the app should start once the splash resolves.
enum LaunchDestination: Equatable {
    /// First run — show the interactive onboarding.
    case onboarding
    /// Onboarded but signed out — show the auth gate.
    case authGate
    /// A persisted session exists — enter the shell directly.
    case main
}

/// Decides the launch destination from onboarding + authorization status.
/// Lives in the app target because the decision spans two features (the
/// onboarding preference and the auth session), which only the composition
/// root may combine — a feature package can't import another.
@MainActor
protocol LaunchUseCase {
    func execute() async -> LaunchDestination
}

struct LaunchUseCaseImpl: LaunchUseCase {
    let hasCompletedOnboarding: @MainActor () -> Bool
    let hasSession: @MainActor () async -> Bool

    /// First run (onboarding not yet completed) → onboarding; otherwise a
    /// persisted session enters the shell and its absence shows the auth gate.
    func execute() async -> LaunchDestination {
        guard hasCompletedOnboarding() else { return .onboarding }
        return await hasSession() ? .main : .authGate
    }
}
