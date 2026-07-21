//
//  ModuleLocalization.swift
//  TMDB
//
//  Created by Ahmed Raslan on 21/07/2026.
//

import Foundation

// MARK: - The module-localization layer

//
// SwiftUI's `Text("key")` and Foundation's `LocalizedStringResource("key")`
// default their string lookup to `Bundle.main` (the app). But each SPM package
// ships its own String Catalog in `Bundle.module`, so package strings only get
// localized when the lookup is pointed at that module's bundle:
//
//   • Views:       `Text("Home", bundle: .module, comment: "…")`
//   • View models: `LocalizedStringResource(moduleKey: "home.error",
//                    defaultValue: "…", bundle: .module, comment: "…")`
//
// This layer provides the view-model convenience (the `Text(bundle:)` form is
// already ergonomic) and centralizes the rule so every feature localizes the
// same way against its own `Localizable.xcstrings`.

public extension LocalizedStringResource {
    /// Builds a resource localized against a specific module's `Bundle`.
    /// Call from a feature package with `bundle: .module` so it resolves in
    /// that package's String Catalog rather than the app bundle.
    init(
        moduleKey key: StaticString,
        defaultValue: String.LocalizationValue,
        bundle: Bundle,
        comment: StaticString
    ) {
        self.init(key, defaultValue: defaultValue, bundle: .atURL(bundle.bundleURL), comment: comment)
    }
}
