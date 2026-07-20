//
//  ProfileViewModel.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

import CoreUI
import Foundation
import Observation

/// Drives the Profile tab: loads the signed-in account + collection counts,
/// or falls into the guest state for anonymous sessions. Loading the account
/// is also what caches the account id, activating favorites/watchlist sync.
@Observable
@MainActor
public final class ProfileViewModel {
    /// Exhaustive screen state.
    public enum ViewState: Equatable {
        case loading
        /// Anonymous session — no account to show.
        case guest
        case loaded(Account, AccountStats)
        case error(LocalizedStringResource)
    }

    public private(set) var state: ViewState = .loading

    private let repository: any ProfileRepository
    private let imageBaseURL: URL

    public init(repository: any ProfileRepository, imageBaseURL: URL) {
        self.repository = repository
        self.imageBaseURL = imageBaseURL
    }

    /// Loads the account and stats. Idempotent once loaded/guest; retryable
    /// from the error state.
    public func load() async {
        switch state {
        case .loaded, .guest:
            return
        case .loading, .error:
            break
        }
        state = .loading
        do {
            let account = try await repository.account()
            // Stats are secondary — a count failure shouldn't blank the page.
            let stats = await (try? repository.stats(for: account.id))
                ?? AccountStats(favoriteCount: 0, watchlistCount: 0)
            state = .loaded(account, stats)
        } catch ProfileError.notAuthenticated {
            state = .guest
        } catch is CancellationError {
            state = .loading
        } catch {
            state = .error(LocalizedStringResource(
                "profile.error",
                defaultValue: "Couldn't load your profile.",
                comment: "Shown when the profile fails to load"
            ))
        }
    }

    /// Avatar URL: the TMDB avatar if set, else a Gravatar fallback, else nil.
    public func avatarURL(for account: Account) -> URL? {
        if let path = account.avatarPath {
            return TMDBImageURL.url(base: imageBaseURL, path: path, size: .w185)
        }
        if let hash = account.gravatarHash {
            return URL(string: "https://www.gravatar.com/avatar/\(hash)?s=200&d=identicon")
        }
        return nil
    }
}
