//
//  RequestTokenAuthorizer.swift
//  TMDB
//
//  Created by Ahmed Raslan on 17/07/2026.
//

/// Presents TMDB's approval page for a request token and returns once the
/// user has approved it. Implemented in Presentation with
/// `ASWebAuthenticationSession` (task 2.3); injected into `LoginUseCase` so
/// the domain stays free of UI frameworks.
public protocol RequestTokenAuthorizer: Sendable {
    /// - Returns: The same token, now approved and exchangeable for a session.
    /// - Throws: `AuthError.userCancelled` if the user dismisses the page.
    func authorize(_ token: RequestToken) async throws -> RequestToken
}
