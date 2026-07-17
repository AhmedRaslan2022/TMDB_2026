// By Ahmed Raslan ®

import Foundation

/// Mutates outgoing requests before they are sent — auth headers, tracing,
/// localization. Interceptors run in the order the client was given them.
public protocol RequestInterceptor: Sendable {
    func adapt(_ request: URLRequest) async throws -> URLRequest
}

/// Injects the TMDB v4 Read Access Token as an `Authorization: Bearer` header.
///
/// The token comes through a provider closure so this module stays independent
/// of CoreEnvironment — the composition root wires the two together.
public struct BearerAuthInterceptor: RequestInterceptor {
    private let tokenProvider: @Sendable () -> String

    public init(tokenProvider: @escaping @Sendable () -> String) {
        self.tokenProvider = tokenProvider
    }

    public func adapt(_ request: URLRequest) async throws -> URLRequest {
        var request = request
        request.setValue("Bearer \(tokenProvider())", forHTTPHeaderField: "Authorization")
        return request
    }
}
