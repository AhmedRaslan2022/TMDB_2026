//
//  WebRequestTokenAuthorizer.swift
//  TMDB
//
//  Created by Ahmed Raslan on 17/07/2026.
//

import AuthenticationServices
import Foundation

/// `RequestTokenAuthorizer` backed by `ASWebAuthenticationSession`: opens
/// TMDB's approval page in the system sheet and resolves once TMDB redirects
/// to our callback scheme.
///
/// `@MainActor` because the session must be created, presented and retained
/// on the main thread; the actor isolation also makes the class `Sendable`.
@MainActor
public final class WebRequestTokenAuthorizer: RequestTokenAuthorizer {
    private let contextProvider = PresentationContextProvider()
    /// Retained for the duration of the flow — the session dismisses itself
    /// if it is deallocated mid-presentation.
    private var activeSession: ASWebAuthenticationSession?

    public init() {}

    public func authorize(_ token: RequestToken) async throws -> RequestToken {
        // One flow at a time: a second call would clobber activeSession and
        // the first defer would tear down the second call's sheet.
        guard activeSession == nil else {
            throw WebAuthFlowError.cannotStart
        }
        try Task.checkCancellation()
        let approvalURL = try TMDBApprovalFlow.approvalURL(for: token)
        defer { activeSession = nil }

        let callbackURL: URL = try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                // Completion-handler API wrapped in a continuation: the OS
                // offers no async variant of ASWebAuthenticationSession.
                let session = ASWebAuthenticationSession(
                    url: approvalURL,
                    callbackURLScheme: TMDBApprovalFlow.callbackScheme
                ) { callbackURL, error in
                    if let error {
                        continuation.resume(throwing: Self.mapSessionError(error))
                    } else if let callbackURL {
                        continuation.resume(returning: callbackURL)
                    } else {
                        continuation.resume(throwing: WebAuthFlowError.invalidCallback)
                    }
                }
                session.presentationContextProvider = contextProvider
                activeSession = session
                if !session.start() {
                    activeSession = nil
                    continuation.resume(throwing: WebAuthFlowError.cannotStart)
                }
            }
        } onCancel: {
            // cancel() fires the completion with .canceledLogin, which maps
            // to AuthError.userCancelled — the continuation always resumes.
            Task { @MainActor in self.activeSession?.cancel() }
        }

        switch TMDBApprovalFlow.outcome(of: callbackURL, expecting: token) {
        case .approved:
            return token
        case .denied:
            throw AuthError.userCancelled
        case .invalid:
            throw AuthError.tokenNotApproved
        }
    }

    private static func mapSessionError(_ error: Error) -> Error {
        if let sessionError = error as? ASWebAuthenticationSessionError,
           sessionError.code == .canceledLogin {
            return AuthError.userCancelled
        }
        return error
    }
}

/// Anchors the approval sheet to the app's key window (or a fresh anchor if
/// none is available yet).
private final class PresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for _: ASWebAuthenticationSession) -> ASPresentationAnchor {
        // Documented to be called on the main thread; the protocol just is
        // not annotated, hence the assumeIsolated bridge.
        MainActor.assumeIsolated {
            #if canImport(UIKit)
                let keyWindow = UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .flatMap(\.windows)
                    .first(where: \.isKeyWindow)
                return keyWindow ?? ASPresentationAnchor()
            #else
                return ASPresentationAnchor()
            #endif
        }
    }
}
