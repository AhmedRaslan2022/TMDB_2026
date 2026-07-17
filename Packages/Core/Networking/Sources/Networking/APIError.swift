// By Ahmed Raslan ®

import Foundation

/// Failures an `APIClient` call can surface, mapped from transport and HTTP
/// layer outcomes so callers never handle raw `URLError`s or status codes.
public enum APIError: Error {
    /// The endpoint could not be composed into a valid URL.
    case invalidURL
    /// The connection itself failed (offline, timeout, DNS, …).
    case transport(URLError)
    /// The response was not an HTTP response at all.
    case invalidResponse
    /// 401 — missing or invalid credentials.
    case unauthorized
    /// 404 — the resource does not exist.
    case notFound
    /// Any other 4xx status.
    case client(statusCode: Int)
    /// Any 5xx status.
    case server(statusCode: Int)
    /// The payload arrived but could not be decoded into the expected type.
    case decoding(DecodingError)
    /// Anything that does not fit the cases above.
    case unknown(Error)
}

extension APIError {
    /// Maps an HTTP status code to its error case, or `nil` for 2xx.
    static func fromStatusCode(_ statusCode: Int) -> APIError? {
        switch statusCode {
        case 200 ..< 300: nil
        case 401: .unauthorized
        case 404: .notFound
        case 400 ..< 500: .client(statusCode: statusCode)
        default: .server(statusCode: statusCode)
        }
    }
}
