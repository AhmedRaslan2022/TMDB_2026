//
//  AppFavoritesAccountProvider.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

import FeatureFavorites
import KeychainStorage

/// Resolves the favorites sync account from the persisted session credentials.
///
/// Returns `nil` today because the account ID isn't stored yet — Profile
/// (task 5.1) fetches `/account` and writes `.accountID`, at which point this
/// starts returning a real account and remote sync activates automatically.
/// Guests never have an account ID, so they stay `nil` permanently.
struct AppFavoritesAccountProvider: FavoritesAccountProviding {
    let secureStorage: any SecureStorage

    func currentAccount() async -> FavoritesAccount? {
        guard let accountIDString = await string(.accountID),
              let accountID = Int(accountIDString),
              let sessionID = await string(.sessionID)
        else { return nil }
        return FavoritesAccount(accountID: accountID, sessionID: sessionID)
    }

    private func string(_ key: SecureStorageKey) async -> String? {
        guard let value = try? await secureStorage.string(for: key) else { return nil }
        return value
    }
}
