//
//  AppThemeColorScheme.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

import CoreModels
import SwiftUI

extension AppTheme {
    /// The SwiftUI color scheme to force at the app root, or `nil` to follow
    /// the system setting.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
