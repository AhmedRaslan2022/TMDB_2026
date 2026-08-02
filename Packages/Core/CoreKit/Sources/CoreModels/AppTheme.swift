//
//  AppTheme.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

/// The user's appearance preference. `system` follows the device setting.
/// Pure domain — the SwiftUI `ColorScheme` mapping lives in the app target,
/// which applies it at the root.
public enum AppTheme: String, CaseIterable, Sendable, Identifiable {
    case system
    case light
    case dark

    public var id: String {
        rawValue
    }
}
