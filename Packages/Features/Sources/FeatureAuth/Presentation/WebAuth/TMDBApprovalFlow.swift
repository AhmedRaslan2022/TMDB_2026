//
//  TMDBApprovalFlow.swift
//  TMDB
//
//  Created by Ahmed Raslan on 17/07/2026.
//

import Foundation

/// Failures of the web-approval machinery itself, as opposed to auth
/// outcomes (`AuthError`) or transport failures (`APIError`).
enum WebAuthFlowError: Error, Equatable {
    /// The approval URL could not be composed.
    case invalidApprovalURL
    /// The web session ended without a callback URL or a recognised error.
    case invalidCallback
    /// `ASWebAuthenticationSession` refused to start.
    case cannotStart
}

/// Pure logic of TMDB's website-approval leg: builds the page URL and
/// interprets the redirect. Kept free of AuthenticationServices so it is
/// unit-testable; `WebRequestTokenAuthorizer` owns the session itself.
enum TMDBApprovalFlow {
    /// Custom scheme intercepted by `ASWebAuthenticationSession`. Not
    /// registered in Info.plist on purpose — the session captures it before
    /// the system ever resolves the URL.
    static let callbackScheme = "tmdb-auth"

    /// What TMDB's redirect said about the token.
    enum Outcome: Equatable {
        /// The user approved this exact token.
        case approved
        /// The user explicitly denied access.
        case denied
        /// The redirect was malformed or referred to a different token.
        case invalid
    }

    /// The TMDB page where the user approves `token`, redirecting to our
    /// callback scheme afterwards.
    static func approvalURL(for token: RequestToken) throws -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "www.themoviedb.org"
        components.path = "/authenticate/\(token.value)"
        components.queryItems = [
            URLQueryItem(name: "redirect_to", value: "\(callbackScheme)://callback"),
        ]
        guard let url = components.url else {
            throw WebAuthFlowError.invalidApprovalURL
        }
        return url
    }

    /// Interprets the callback redirect for the token we asked about.
    /// TMDB appends `request_token` and either `approved=true` or
    /// `denied=true` to the redirect target.
    static func outcome(of callbackURL: URL, expecting token: RequestToken) -> Outcome {
        guard
            let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
            let queryItems = components.queryItems
        else {
            return .invalid
        }
        let values = Dictionary(
            queryItems.map { ($0.name, $0.value ?? "") },
            uniquingKeysWith: { first, _ in first }
        )

        if values["denied"] == "true" {
            return .denied
        }
        guard values["approved"] == "true", values["request_token"] == token.value else {
            return .invalid
        }
        return .approved
    }
}
