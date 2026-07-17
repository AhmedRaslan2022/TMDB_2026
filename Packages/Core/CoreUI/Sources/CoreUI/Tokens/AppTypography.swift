//
//  AppTypography.swift
//  TMDB
//
//  Created by Ahmed Raslan on 15/07/2026.
//

import SwiftUI

/// Typography tokens. All styles are Dynamic Type–relative — never fixed
/// point sizes — so accessibility scaling works everywhere.
public enum AppTypography {
    /// Screen titles (e.g. section headers on Home).
    public static let screenTitle = Font.title.weight(.bold)
    /// Card and row titles.
    public static let title = Font.headline
    /// Standard body copy.
    public static let body = Font.body
    /// Metadata: dates, runtimes, vote counts.
    public static let caption = Font.caption
    /// Small emphasized labels: badges, genre chips.
    public static let label = Font.footnote.weight(.semibold)
}
