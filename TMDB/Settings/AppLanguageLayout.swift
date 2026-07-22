//
//  AppLanguageLayout.swift
//  TMDB
//
//  Created by Ahmed Raslan on 21/07/2026.
//

import CoreModels
import SwiftUI

extension AppLanguage {
    /// The UI locale to render in. Setting this on the root environment makes
    /// SwiftUI resolve strings from the module catalogs in this language live —
    /// no relaunch — so changing the content language also switches the UI.
    var locale: Locale {
        Locale(identifier: rawValue)
    }

    /// Right-to-left for Arabic, left-to-right otherwise. Applied to the root so
    /// the whole shell mirrors when the user picks Arabic.
    var layoutDirection: LayoutDirection {
        switch self {
        case .arabic: .rightToLeft
        case .english: .leftToRight
        }
    }
}
