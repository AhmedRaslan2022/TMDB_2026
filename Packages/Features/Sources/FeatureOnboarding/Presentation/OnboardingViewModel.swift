//
//  OnboardingViewModel.swift
//  TMDB
//
//  Created by Ahmed Raslan on 26/07/2026.
//

import Observation

/// Drives the onboarding walkthrough: the current slide and the advance / skip
/// intents. Finishing (advancing past the last slide, or skipping) calls the
/// `OnboardingCompletion` port exactly once so the app can persist it.
@Observable
@MainActor
public final class OnboardingViewModel {
    public let pages: [OnboardingPage]
    /// Index of the visible slide; bound to the paged view.
    public var currentIndex: Int = 0

    @ObservationIgnored private let completion: any OnboardingCompletion
    @ObservationIgnored private var didComplete = false

    public init(pages: [OnboardingPage] = .onboardingDefault, completion: any OnboardingCompletion) {
        precondition(!pages.isEmpty, "Onboarding needs at least one page")
        self.pages = pages
        self.completion = completion
    }

    /// Whether the current slide is the last one (the CTA becomes "Get Started").
    public var isOnLastPage: Bool {
        currentIndex >= pages.count - 1
    }

    /// Primary CTA: advance to the next slide, or finish on the last one.
    public func advance() {
        if isOnLastPage {
            finish()
        } else {
            currentIndex += 1
        }
    }

    /// Secondary CTA: skip the rest and finish immediately.
    public func skip() {
        finish()
    }

    /// Notifies the app once. Guarded so a double-tap can't complete twice.
    private func finish() {
        guard !didComplete else { return }
        didComplete = true
        completion.completeOnboarding()
    }
}
