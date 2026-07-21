//
//  LanguageQueryInterceptor.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

import Foundation

/// Appends TMDB's `language` (and optional `region`) query parameters to every
/// request, so API-returned titles/overviews come back in the user's language
/// and release dates/availability reflect their region.
///
/// The values come through provider closures evaluated per request, so a
/// settings change takes effect on the next call without rebuilding the client.
/// A parameter already present on the request is left untouched.
public struct LanguageQueryInterceptor: RequestInterceptor {
    private let languageProvider: @Sendable () -> String
    private let regionProvider: @Sendable () -> String?

    /// - Parameters:
    ///   - languageProvider: The ISO 639-1 content language (e.g. `"ar"`).
    ///   - regionProvider: The ISO 3166-1 region (e.g. `"EG"`), or `nil` to
    ///     omit `region`. Defaults to omitting it.
    public init(
        languageProvider: @escaping @Sendable () -> String,
        regionProvider: @escaping @Sendable () -> String? = { nil }
    ) {
        self.languageProvider = languageProvider
        self.regionProvider = regionProvider
    }

    public func adapt(_ request: URLRequest) async throws -> URLRequest {
        guard let url = request.url,
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else { return request }

        var items = components.queryItems ?? []
        appendIfAbsent("language", value: languageProvider(), to: &items)
        if let region = regionProvider(), !region.isEmpty {
            appendIfAbsent("region", value: region, to: &items)
        }
        components.queryItems = items

        var request = request
        request.url = components.url ?? url
        return request
    }

    private func appendIfAbsent(_ name: String, value: String, to items: inout [URLQueryItem]) {
        guard !items.contains(where: { $0.name == name }) else { return }
        items.append(URLQueryItem(name: name, value: value))
    }
}
