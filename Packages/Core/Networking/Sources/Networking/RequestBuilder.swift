//
//  RequestBuilder.swift
//  TMDB
//
//  Created by Ahmed Raslan on 15/07/2026.
//

import Foundation

/// Turns an `Endpoint` into a `URLRequest` against a base URL.
enum RequestBuilder {
    static func makeRequest(for endpoint: some Endpoint, baseURL: URL) throws -> URLRequest {
        let url = baseURL.appending(path: endpoint.path)
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw APIError.invalidURL
        }
        if !endpoint.queryItems.isEmpty {
            components.queryItems = endpoint.queryItems
        }
        guard let finalURL = components.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: finalURL)
        request.httpMethod = endpoint.method.rawValue
        request.httpBody = endpoint.body
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if endpoint.body != nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        for (field, value) in endpoint.headers {
            request.setValue(value, forHTTPHeaderField: field)
        }
        return request
    }
}
