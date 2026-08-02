//
//  AppEnvironment.swift
//  TMDB
//
//  Created by Ahmed Raslan on 15/07/2026.
//

import Foundation

/// Type-safe view over the per-environment configuration injected through
/// xcconfig files into the app's Info.plist.
///
/// Values are read once at launch; a malformed or incomplete configuration is
/// a build-setup bug, so the non-throwing entry point traps in debug with a
/// message naming the missing key.
public struct AppEnvironment: Sendable, Equatable {
    /// The four build environments defined in `Configs/*.xcconfig`.
    public enum Name: String, Sendable {
        case dev = "Dev"
        case staging = "Staging"
        case test = "Test"
        case live = "Live"
    }

    /// Which environment this binary was built for.
    public let name: Name
    /// Base URL for TMDB API v3 endpoints.
    public let apiBaseURL: URL
    /// Base URL for TMDB image assets.
    public let imageBaseURL: URL
    /// TMDB v4 Read Access Token, sent as an `Authorization: Bearer` header.
    public let accessToken: String

    /// Memberwise initializer, primarily for tests and previews.
    public init(name: Name, apiBaseURL: URL, imageBaseURL: URL, accessToken: String) {
        self.name = name
        self.apiBaseURL = apiBaseURL
        self.imageBaseURL = imageBaseURL
        self.accessToken = accessToken
    }
}

public extension AppEnvironment {
    /// A configuration problem detected while reading the info dictionary.
    enum ReadError: Error, Equatable {
        case missingKey(String)
        case invalidValue(key: String, value: String)
    }

    /// Info.plist keys, populated from `Configs/*.xcconfig` build settings.
    enum Key: String, CaseIterable, Sendable {
        case name = "APP_ENVIRONMENT_NAME"
        case apiBaseURL = "TMDB_API_BASE_URL"
        case imageBaseURL = "TMDB_IMAGE_BASE_URL"
        case accessToken = "TMDB_ACCESS_TOKEN"
    }

    /// Reads the environment from an info dictionary. Throwing so tests can
    /// assert on every failure mode.
    init(infoDictionary: [String: Any]) throws {
        func string(_ key: Key) throws -> String {
            guard let raw = infoDictionary[key.rawValue] as? String, !raw.isEmpty else {
                throw ReadError.missingKey(key.rawValue)
            }
            return raw
        }
        func url(_ key: Key) throws -> URL {
            let raw = try string(key)
            guard let url = URL(string: raw), url.scheme != nil else {
                throw ReadError.invalidValue(key: key.rawValue, value: raw)
            }
            return url
        }

        let rawName = try string(.name)
        guard let name = Name(rawValue: rawName) else {
            throw ReadError.invalidValue(key: Key.name.rawValue, value: rawName)
        }

        let token = try string(.accessToken)

        try self.init(
            name: name,
            apiBaseURL: url(.apiBaseURL),
            imageBaseURL: url(.imageBaseURL),
            accessToken: token
        )
    }

    /// Reads the environment from a bundle, trapping on misconfiguration —
    /// a missing key means the xcconfig/Info.plist wiring is broken and the
    /// build itself is invalid.
    static func load(from bundle: Bundle = .main) -> AppEnvironment {
        do {
            return try AppEnvironment(infoDictionary: bundle.infoDictionary ?? [:])
        } catch let error as ReadError {
            preconditionFailure("AppEnvironment misconfigured: \(error)")
        } catch {
            preconditionFailure("AppEnvironment misconfigured: \(error)")
        }
    }
}
