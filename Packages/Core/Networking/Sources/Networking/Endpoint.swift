// By Ahmed Raslan ®

import Foundation

/// Declarative description of a single API call. Conforming types are cheap
/// value types declared in feature Data layers; the client turns them into
/// `URLRequest`s against its base URL.
public protocol Endpoint: Sendable {
    /// Path relative to the client's base URL, e.g. `"/configuration"`.
    var path: String { get }
    var method: HTTPMethod { get }
    var queryItems: [URLQueryItem] { get }
    /// Additional headers for this call. Client-wide headers (auth) are
    /// applied by interceptors, not here.
    var headers: [String: String] { get }
    /// JSON-encoded body, if any.
    var body: Data? { get }
}

public extension Endpoint {
    var method: HTTPMethod {
        .get
    }

    var queryItems: [URLQueryItem] {
        []
    }

    var headers: [String: String] {
        [:]
    }

    var body: Data? {
        nil
    }
}
