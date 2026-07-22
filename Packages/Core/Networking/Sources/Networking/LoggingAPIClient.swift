//
//  LoggingAPIClient.swift
//  TMDB
//
//  Created by Ahmed Raslan on 21/07/2026.
//

import CoreUtilities
import Foundation

/// An `APIClient` decorator that logs each request (method, path, redacted
/// query/headers/body) and its response as pretty-printed, redacted JSON with a
/// duration — same interface as what it wraps, so it drops in transparently at
/// the composition root.
///
/// Only wired in for the Dev/Test environments (see the composition root);
/// never in Staging/Live. Secrets are never logged: the `Authorization: Bearer`
/// token is added by an interceptor *inside* the wrapped client and is invisible
/// here, and any sensitive key (`session_id`, `api_key`, …) is redacted to `•••`
/// in the query, headers, request body, **and the response body** (recursively).
///
/// The raw response bytes only exist at the `sendRaw` boundary, so `send(_:)` is
/// composed as `sendRaw` + decode — exactly what `URLSessionAPIClient` does
/// internally — letting the decorator log the JSON body of *every* request.
/// Both share the `JSONDecoder.tmdb` factory, so the typed value the caller
/// receives is identical whether or not this decorator is in place.
public struct LoggingAPIClient: APIClient {
    private let wrapped: any APIClient
    private let decoder: JSONDecoder
    private let log: @Sendable (String) -> Void

    /// Composition-root entry point — logs through the shared `AppLogger`.
    public init(wrapping client: any APIClient, category: String = "Network") {
        let logger = AppLogger(category: category)
        self.init(wrapping: client, log: { logger.debug($0) })
    }

    /// Test seam — inject a capturing sink to assert on the emitted lines.
    init(wrapping client: any APIClient, log: @escaping @Sendable (String) -> Void) {
        wrapped = client
        // Same shared factory URLSessionAPIClient uses, so the typed value the
        // caller receives is identical whether or not this decorator is present.
        decoder = .tmdb
        self.log = log
    }

    public func send<T: Decodable & Sendable>(_ endpoint: some Endpoint) async throws -> T {
        // Route through sendRaw so the JSON body is logged, then decode exactly
        // as the wrapped client would — same result, same APIError.decoding.
        let data = try await sendRaw(endpoint)
        do {
            return try decoder.decode(T.self, from: data)
        } catch let error as DecodingError {
            log("📥 ❌ \(endpoint.method.rawValue) \(endpoint.path) decode → \(Self.safeDescription(APIError.decoding(error)))")
            throw APIError.decoding(error)
        }
    }

    @discardableResult
    public func sendRaw(_ endpoint: some Endpoint) async throws -> Data {
        log(Self.requestLog(endpoint))
        let start = ContinuousClock.now
        do {
            let data = try await wrapped.sendRaw(endpoint)
            log(Self.responseLog(endpoint, data: data, duration: elapsed(since: start)))
            return data
        } catch is CancellationError {
            log("🚫 \(endpoint.method.rawValue) \(endpoint.path) cancelled \(elapsed(since: start))")
            throw CancellationError()
        } catch {
            log("📥 ❌ \(endpoint.method.rawValue) \(endpoint.path) → \(Self.safeDescription(error)) \(elapsed(since: start))")
            throw error
        }
    }

    // MARK: Rendering

    /// The 📤 request block: method + path followed by its components (query,
    /// headers, body), each with secrets redacted.
    private static func requestLog(_ endpoint: some Endpoint) -> String {
        var lines = ["📤 \(endpoint.method.rawValue) \(endpoint.path)"]
        if !endpoint.queryItems.isEmpty {
            let query = endpoint.queryItems
                .map { "\($0.name)=\(redact($0.name, $0.value ?? ""))" }
                .joined(separator: "&")
            lines.append("   • query: \(query)")
        }
        if !endpoint.headers.isEmpty {
            let headers = endpoint.headers
                .map { "\($0.key)=\(redact($0.key, $0.value))" }
                .sorted()
                .joined(separator: ", ")
            lines.append("   • headers: \(headers)")
        }
        if let body = endpoint.body {
            lines.append("   🧩 body:\n\(prettyJSON(body, limit: 2000))")
        }
        return lines.joined(separator: "\n")
    }

    /// The 📥 response block: the beautified, redacted JSON body under the
    /// method/path/duration header line.
    private static func responseLog(_ endpoint: some Endpoint, data: Data, duration: String) -> String {
        "📥 ✅ \(endpoint.method.rawValue) \(endpoint.path) \(duration)\n\(prettyJSON(data, limit: 8000))"
    }

    private func elapsed(since start: ContinuousClock.Instant) -> String {
        Self.format(start.duration(to: .now))
    }

    /// Formats a `Duration` as whole milliseconds. `components` splits into
    /// `(seconds, attoseconds-remainder)`, so both parts must be summed —
    /// using only the attoseconds remainder silently drops every whole second.
    static func format(_ duration: Duration) -> String {
        let parts = duration.components
        let ms = Double(parts.seconds) * 1000 + Double(parts.attoseconds) / 1e15
        return "⏱ \(String(format: "%.0f", ms))ms"
    }

    /// A description safe to log. The raw error is never interpolated: an
    /// `APIError.transport(URLError)` embeds the full request URL — query
    /// secrets included — in `NSErrorFailingURLKey`, and a `DecodingError`'s
    /// debug description can embed response snippets. Only stable, secret-free
    /// case labels and status codes are emitted.
    static func safeDescription(_ error: Error) -> String {
        guard let apiError = error as? APIError else {
            return String(describing: type(of: error))
        }
        switch apiError {
        case .invalidURL: return "invalidURL"
        case let .transport(urlError): return "transport(URLError \(urlError.code.rawValue))"
        case .invalidResponse: return "invalidResponse"
        case .unauthorized: return "unauthorized (401)"
        case .notFound: return "notFound (404)"
        case let .client(statusCode): return "client(\(statusCode))"
        case let .server(statusCode): return "server(\(statusCode))"
        case let .decoding(decodingError): return "decoding(\(label(decodingError)))"
        case let .unknown(underlying): return "unknown(\(type(of: underlying)))"
        }
    }

    /// The `DecodingError` case name only — never its associated context,
    /// which can carry response data.
    private static func label(_ error: DecodingError) -> String {
        switch error {
        case .typeMismatch: return "typeMismatch"
        case .valueNotFound: return "valueNotFound"
        case .keyNotFound: return "keyNotFound"
        case .dataCorrupted: return "dataCorrupted"
        @unknown default: return "unknown"
        }
    }

    // MARK: Redaction

    /// Keys whose values must never be logged, in query, headers, or JSON.
    private static let sensitiveKeys: Set<String> = [
        "session_id", "guest_session_id", "api_key", "request_token", "access_token", "authorization",
    ]

    private static func redact(_ key: String, _ value: String) -> String {
        sensitiveKeys.contains(key.lowercased()) ? "•••" : value
    }

    /// Beautifies a JSON payload with every sensitive value redacted; falls back
    /// to a byte count for non-JSON (e.g. images). Truncated so logs stay sane.
    private static func prettyJSON(_ data: Data, limit: Int) -> String {
        guard !data.isEmpty else { return "(empty body)" }
        guard let json = try? JSONSerialization.jsonObject(with: data) else {
            return "\(data.count) bytes (non-JSON)"
        }
        guard let pretty = try? JSONSerialization.data(
            withJSONObject: redactJSON(json),
            options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        ), let text = String(data: pretty, encoding: .utf8) else {
            return "\(data.count) bytes"
        }
        return text.count > limit ? String(text.prefix(limit)) + "\n… (truncated, \(text.count) chars total)" : text
    }

    /// Recursively replaces every sensitive key's value with `•••`, descending
    /// through nested objects and arrays so a secret can't hide below the root.
    private static func redactJSON(_ value: Any) -> Any {
        switch value {
        case let object as [String: Any]:
            object.reduce(into: [String: Any]()) { result, pair in
                result[pair.key] = sensitiveKeys.contains(pair.key.lowercased()) ? "•••" : redactJSON(pair.value)
            }
        case let array as [Any]:
            array.map(redactJSON)
        default:
            value
        }
    }
}
