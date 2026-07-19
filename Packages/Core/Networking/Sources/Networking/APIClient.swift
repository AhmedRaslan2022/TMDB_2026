//
//  APIClient.swift
//  TMDB
//
//  Created by Ahmed Raslan on 15/07/2026.
//

import Foundation

/// Sends `Endpoint`s and decodes their JSON responses.
public protocol APIClient: Sendable {
    /// Performs the call and decodes the response body into `T`.
    func send<T: Decodable & Sendable>(_ endpoint: some Endpoint) async throws -> T

    /// Performs the call and returns the raw body, for callers that only
    /// need the status side effect or non-JSON payloads.
    @discardableResult
    func sendRaw(_ endpoint: some Endpoint) async throws -> Data
}

/// `URLSession`-backed client. Decodes snake_case JSON as produced by the
/// TMDB API. All errors surface as `APIError`.
public final class URLSessionAPIClient: APIClient {
    private let baseURL: URL
    private let session: URLSession
    private let interceptors: [any RequestInterceptor]
    private let decoder: JSONDecoder

    /// - Parameters:
    ///   - baseURL: Root of the API, e.g. `https://api.themoviedb.org/3`.
    ///   - session: Injectable for `URLProtocol`-stubbed tests.
    ///   - interceptors: Applied to every request, in order (e.g. auth).
    public init(baseURL: URL, session: URLSession = .shared, interceptors: [any RequestInterceptor] = []) {
        self.baseURL = baseURL
        self.session = session
        self.interceptors = interceptors
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder
    }

    public func send<T: Decodable & Sendable>(_ endpoint: some Endpoint) async throws -> T {
        let data = try await sendRaw(endpoint)
        do {
            return try decoder.decode(T.self, from: data)
        } catch let error as DecodingError {
            throw APIError.decoding(error)
        }
    }

    @discardableResult
    public func sendRaw(_ endpoint: some Endpoint) async throws -> Data {
        var request = try RequestBuilder.makeRequest(for: endpoint, baseURL: baseURL)
        for interceptor in interceptors {
            request = try await interceptor.adapt(request)
        }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError where error.code == .cancelled {
            // Normalize to Swift's cancellation so ViewModels can treat a
            // dismissed screen as "back to idle" rather than an error.
            throw CancellationError()
        } catch let error as URLError {
            throw APIError.transport(error)
        } catch {
            throw APIError.unknown(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        if let error = APIError.fromStatusCode(httpResponse.statusCode) {
            throw error
        }
        return data
    }
}
