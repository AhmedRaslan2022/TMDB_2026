//
//  LanguageQueryInterceptor.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

import Foundation

/// Appends TMDB's `language` query parameter to every request, so API-returned
/// titles and overviews come back in the user's chosen language.
///
/// The code comes through a provider closure evaluated per request, so a
/// settings change takes effect on the next call without rebuilding the client.
/// Requests that already carry a `language` item are left untouched.
public struct LanguageQueryInterceptor: RequestInterceptor {
    private let languageProvider: @Sendable () -> String

    public init(languageProvider: @escaping @Sendable () -> String) {
        self.languageProvider = languageProvider
    }

    public func adapt(_ request: URLRequest) async throws -> URLRequest {
        guard let url = request.url,
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else { return request }

        var items = components.queryItems ?? []
        guard !items.contains(where: { $0.name == "language" }) else { return request }
        items.append(URLQueryItem(name: "language", value: languageProvider()))
        components.queryItems = items

        var request = request
        request.url = components.url ?? url
        return request
    }
}
