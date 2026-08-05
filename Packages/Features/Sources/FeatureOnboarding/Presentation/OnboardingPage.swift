//
//  OnboardingPage.swift
//  TMDB
//
//  Created by Ahmed Raslan on 26/07/2026.
//

import Foundation

/// One onboarding slide: an SF Symbol plus a localized title and message.
/// Localized against this package's String Catalog (`bundle: .module`).
public struct OnboardingPage: Identifiable, Sendable {
    public let id: Int
    public let systemImage: String
    public let title: LocalizedStringResource
    public let message: LocalizedStringResource

    public init(id: Int, systemImage: String, title: LocalizedStringResource, message: LocalizedStringResource) {
        self.id = id
        self.systemImage = systemImage
        self.title = title
        self.message = message
    }
}

public extension [OnboardingPage] {
    /// The default three-slide walkthrough shown on first launch.
    static var onboardingDefault: [OnboardingPage] {
        [
            OnboardingPage(
                id: 0,
                systemImage: "film.stack",
                title: .module("onboarding.discover.title", "Discover Movies & TV"),
                message: .module("onboarding.discover.message", "Browse what's trending and explore casts and crews.")
            ),
            OnboardingPage(
                id: 1,
                systemImage: "heart.text.square",
                title: .module("onboarding.collect.title", "Build Your Collection"),
                message: .module("onboarding.collect.message", "Save favorites, keep a watchlist, and rate what you watch.")
            ),
            OnboardingPage(
                id: 2,
                systemImage: "globe",
                title: .module("onboarding.made.title", "Made for You"),
                message: .module("onboarding.made.message", "English and Arabic, right-to-left layout, light and dark.")
            ),
        ]
    }
}

private extension LocalizedStringResource {
    /// A resource localized against this package's String Catalog.
    static func module(_ key: StaticString, _ value: String.LocalizationValue) -> LocalizedStringResource {
        LocalizedStringResource(moduleKey: key, defaultValue: value, bundle: .module, comment: "Onboarding copy")
    }
}
