//
//  LanguageQueryInterceptorTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

import Foundation
import Testing
@testable import Networking

struct LanguageQueryInterceptorTests {
    private func components(_ request: URLRequest) throws -> URLComponents {
        let url = try #require(request.url)
        return try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
    }

    @Test func appendsLanguageQueryItem() async throws {
        let interceptor = LanguageQueryInterceptor(languageProvider: { "ar" })
        let request = try URLRequest(url: #require(URL(string: "https://api.example.com/3/movie/popular")))

        let adapted = try await interceptor.adapt(request)

        let items = try #require(try components(adapted).queryItems)
        #expect(items.contains(URLQueryItem(name: "language", value: "ar")))
    }

    @Test func preservesExistingQueryItems() async throws {
        let interceptor = LanguageQueryInterceptor(languageProvider: { "en" })
        let request = try URLRequest(url: #require(URL(string: "https://api.example.com/3/search/movie?query=dune&page=2")))

        let adapted = try await interceptor.adapt(request)

        let items = try #require(try components(adapted).queryItems)
        #expect(items.contains(URLQueryItem(name: "query", value: "dune")))
        #expect(items.contains(URLQueryItem(name: "page", value: "2")))
        #expect(items.contains(URLQueryItem(name: "language", value: "en")))
    }

    @Test func doesNotDuplicateAnExistingLanguageItem() async throws {
        let interceptor = LanguageQueryInterceptor(languageProvider: { "en" })
        let request = try URLRequest(url: #require(URL(string: "https://api.example.com/3/movie/1?language=fr")))

        let adapted = try await interceptor.adapt(request)

        let languageItems = try components(adapted).queryItems?.filter { $0.name == "language" }
        #expect(languageItems?.count == 1)
        #expect(languageItems?.first?.value == "fr", "an explicit per-request language wins")
    }

    @Test func providerEvaluatedPerRequest() async throws {
        let current = LockedLanguage(value: "en")
        let interceptor = LanguageQueryInterceptor(languageProvider: { current.value })
        let makeRequest = { try URLRequest(url: #require(URL(string: "https://api.example.com/3/movie/1"))) }

        let first = try await interceptor.adapt(makeRequest())
        current.value = "ar"
        let second = try await interceptor.adapt(makeRequest())

        #expect(try components(first).queryItems?.first { $0.name == "language" }?.value == "en")
        #expect(try components(second).queryItems?.first { $0.name == "language" }?.value == "ar")
    }

    /// Minimal mutable box so the provider closure can observe a change.
    private final class LockedLanguage: @unchecked Sendable {
        var value: String
        init(value: String) {
            self.value = value
        }
    }
}
