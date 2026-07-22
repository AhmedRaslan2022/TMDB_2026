//
//  AppIconController.swift
//  TMDB
//
//  Created by Ahmed Raslan on 21/07/2026.
//

import CoreModels
import UIKit

/// Applies the user's chosen alternate app icon. A protocol so `AppSettings`
/// depends on the capability, not `UIApplication` — which keeps it unit-testable.
@MainActor
protocol AppIconControlling: Sendable {
    func apply(_ icon: AppIcon)
}

/// Maps `AppIcon` to the asset catalog's alternate-icon names and drives
/// `UIApplication.setAlternateIconName`. `nil` restores the environment's
/// primary icon. No-op when the system reports alternate icons unsupported.
struct AppIconController: AppIconControlling {
    func apply(_ icon: AppIcon) {
        guard UIApplication.shared.supportsAlternateIcons else { return }
        let name = Self.alternateName(for: icon)
        // Skip a redundant set — iOS shows a system alert on every change.
        guard UIApplication.shared.alternateIconName != name else { return }
        UIApplication.shared.setAlternateIconName(name)
    }

    /// The catalog appiconset name, or `nil` for the primary icon.
    static func alternateName(for icon: AppIcon) -> String? {
        switch icon {
        case .default: nil
        case .midnight: "AppIcon-Midnight"
        case .sunset: "AppIcon-Sunset"
        }
    }
}
