//
//  AppLanguage.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

/// The content language the app requests from TMDB. The `rawValue` is the
/// ISO 639-1 code, which doubles as the API's `language` value. Full UI
/// localization (RTL, String Catalogs) arrives in Sprint 8; this drives the
/// language of API-returned titles and overviews today.
public enum AppLanguage: String, CaseIterable, Sendable, Identifiable {
    case english = "en"
    case arabic = "ar"

    public var id: String {
        rawValue
    }

    /// The supported language matching an ISO 639-1 language code (e.g. the
    /// device's), falling back to English for anything unsupported or absent.
    /// Used to seed the content language from the device on first launch.
    public static func matching(languageCode: String?) -> AppLanguage {
        guard let languageCode else { return .english }
        return AppLanguage(rawValue: languageCode.lowercased()) ?? .english
    }
}
