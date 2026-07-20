//
//  ProfileError.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

/// Profile-flow failures presentation must distinguish from generic errors.
public enum ProfileError: Error, Equatable {
    /// No authenticated session — a guest or logged-out user has no account.
    case notAuthenticated
}
