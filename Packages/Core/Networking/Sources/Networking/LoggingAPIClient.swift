//
//  LoggingAPIClient.swift
//  TMDB
//
//  Created by Ahmed Raslan on 21/07/2026.
//

import CoreUtilities
import Foundation

/// An `APIClient` decorator that logs each request (method, path, redacted
/// query/body) and its response (or error) with a duration — same interface as
/// what it wraps, so it drops in transparently at the composition root.
///
/// Only wired in for the Dev/Test environments (see the composition root);
/// never in Staging/Live. Secrets are never logged: the `Authorization: Bearer`
/// token is added by an interceptor *inside* the wrapped client and is invisible
/// here, and any sensitive query/header/body keys (`session_id`, `api_key`, …)
/// are redacted to `•••`.
public struct LoggingAPIClient: APIClient {
    private let wrapped: any APIClient
    private let log: @Sendable (String) -> Void

    /// Composition-root entry point — logs through the shared `AppLogger`.
    public init(wrapping client: any APIClient, category: String = "Network") {
        let logger = AppLogger(category: category)
        self.init(wrapping: client, log: { logger.debug($0) })
    }

    /// Test seam — inject a capturing sink to assert on the emitted lines.
    init(wrapping client: any APIClient, log: @escaping @Sendable (String) -> Void) {
        wrapped = client
        self.log = log
    }

    public func send<T: Decodable & Sendable>(_ endpoint: some Endpoint) async throws -> T {
        try await logging(
            endpoint,
            outcome: { _ in "→ \(T.self)" },
            perform: { try await wrapped.send($0) }
        )
    }

    @discardableResult
    public func sendRaw(_ endpoint: some Endpoint) async throws -> Data {
        try await logging(
            endpoint,
            outcome: { "\($0.count) bytes" },
            perform: { try await wrapped.sendRaw($0) }
        )
    }

    /// Shared request/response/error logging around a delegated call.
    private func logging<E: Endpoint, R>(
        _ endpoint: E,
        outcome: @Sendable (R) -> String,
        perform: (E) async throws -> R
    ) async throws -> R {
        log("📤 \(requestLine(endpoint))")
        let start = ContinuousClock.now
        do {
            let result = try await perform(endpoint)
            log("📥 ✅ \(endpoint.method.rawValue) \(endpoint.path) \(outcome(result)) \(elapsed(since: start))")
            return result
        } catch is CancellationError {
            log("🚫 \(endpoint.method.rawValue) \(endpoint.path) cancelled \(elapsed(since: start))")
            throw CancellationError()
        } catch {
            log("📥 ❌ \(endpoint.method.rawValue) \(endpoint.path) → \(Self.safeDescription(error)) \(elapsed(since: start))")
            throw error
        }
    }

    private func requestLine(_ endpoint: some Endpoint) -> String {
        var line = "\(endpoint.method.rawValue) \(endpoint.path)"
        let query = endpoint.queryItems
        if !query.isEmpty {
            line += "?" + query.map { "\($0.name)=\(Self.redact($0.name, $0.value ?? ""))" }.joined(separator: "&")
        }
        if let body = endpoint.body, let text = Self.redactedBody(body) {
            line += " 🧩 \(text)"
        }
        return line
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

    /// Query/header/body keys whose values must never be logged.
    private static let sensitiveKeys: Set<String> = [
        "session_id", "guest_session_id", "api_key", "request_token", "access_token", "authorization",
    ]

    private static func redact(_ key: String, _ value: String) -> String {
        sensitiveKeys.contains(key.lowercased()) ? "•••" : value
    }

    /// Renders a JSON body with sensitive keys redacted at every nesting level;
    /// falls back to a byte count for non-JSON. Truncated so logs stay readable.
    private static func redactedBody(_ data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) else {
            return "\(data.count) bytes"
        }
        guard let redacted = try? JSONSerialization.data(withJSONObject: redactJSON(json)),
              let text = String(data: redacted, encoding: .utf8)
        else { return "\(data.count) bytes" }
        return text.count > 500 ? String(text.prefix(500)) + "…" : text
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
