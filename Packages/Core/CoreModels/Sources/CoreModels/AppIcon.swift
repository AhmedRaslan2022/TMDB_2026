//
//  AppIcon.swift
//  TMDB
//
//  Created by Ahmed Raslan on 21/07/2026.
//

/// A user-selectable alternate app icon. Pure domain — the mapping to the asset
/// catalog's alternate-icon names lives in the app target (`AppIconController`),
/// keeping this free of platform/wire detail.
public enum AppIcon: String, CaseIterable, Sendable, Identifiable {
    /// The environment's primary icon (no alternate applied).
    case `default`
    case midnight
    case sunset

    public var id: String {
        rawValue
    }
}
