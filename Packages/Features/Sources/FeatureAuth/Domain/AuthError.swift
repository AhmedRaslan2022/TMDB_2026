//
//  AuthError.swift
//  TMDB
//
//  Created by Ahmed Raslan on 17/07/2026.
//

/// Auth failures that presentation must distinguish from generic errors.
/// Transport and decoding failures propagate as the data layer's own errors.
public enum AuthError: Error, Equatable {
    /// The user dismissed TMDB's approval page without granting access.
    /// Presentation treats this as a return to idle, not an error state.
    case userCancelled
    /// TMDB reported the request token was not approved by the user.
    case tokenNotApproved
}
