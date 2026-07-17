// By Ahmed Raslan ®

import SwiftUI

/// Semantic color tokens. Views use these — never raw `Color` literals — so
/// theming (Sprint 8) only touches this file.
public enum AppColors {
    // MARK: Brand

    /// TMDB dark blue — primary brand surface.
    public static let brandPrimary = Color(red: 0.05, green: 0.14, blue: 0.25)
    /// TMDB teal — accents and highlights.
    public static let brandSecondary = Color(red: 0.01, green: 0.71, blue: 0.85)
    /// TMDB light green — success/positive accents.
    public static let brandTertiary = Color(red: 0.56, green: 0.83, blue: 0.61)

    // MARK: Semantic

    /// Primary text on standard surfaces.
    public static let textPrimary = Color.primary
    /// De-emphasized text: captions, metadata.
    public static let textSecondary = Color.secondary
    /// Destructive actions and error states.
    public static let error = Color.red
    /// Rating indicators (stars, score rings).
    public static let rating = Color.yellow
}
