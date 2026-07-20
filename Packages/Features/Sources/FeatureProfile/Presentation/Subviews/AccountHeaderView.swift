//
//  AccountHeaderView.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

import CoreUI
import SwiftUI

/// The profile header: avatar, name/username, and the favorites/watchlist
/// stat tiles — or a guest prompt for anonymous sessions.
struct AccountHeaderView: View {
    enum Content: Equatable {
        case account(Account, AccountStats)
        case guest
    }

    let state: Content
    let avatarURL: URL?

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            avatar
            identity
            if case let .account(_, stats) = state {
                statsRow(stats)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.sm)
    }

    private var avatar: some View {
        RemoteImage(url: avatarURL) { image in
            image.resizable().scaledToFill()
        } placeholder: {
            Circle()
                .fill(AppColors.brandPrimary.opacity(0.15))
                .overlay {
                    Image(systemName: "person.fill")
                        .font(.largeTitle)
                        .foregroundStyle(AppColors.textSecondary)
                        .accessibilityHidden(true)
                }
        }
        .frame(width: 88, height: 88)
        .clipShape(Circle())
    }

    @ViewBuilder
    private var identity: some View {
        switch state {
        case let .account(account, _):
            VStack(spacing: AppSpacing.xs) {
                Text(account.name ?? account.username)
                    .font(AppTypography.title)
                    .accessibilityIdentifier("profile.username")
                if account.name != nil {
                    Text(verbatim: "@\(account.username)")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
        case .guest:
            VStack(spacing: AppSpacing.xs) {
                Text("Browsing as Guest", comment: "Profile header for anonymous sessions")
                    .font(AppTypography.title)
                Text("Sign in to sync favorites and more.", comment: "Guest profile prompt")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
    }

    private func statsRow(_ stats: AccountStats) -> some View {
        HStack(spacing: AppSpacing.xl) {
            StatTile(
                value: stats.favoriteCount,
                label: Text("Favorites", comment: "Favorites stat label"),
                systemImage: "heart.fill",
                accessibilityID: "profile.stat.favorites"
            )
            StatTile(
                value: stats.watchlistCount,
                label: Text("Watchlist", comment: "Watchlist stat label"),
                systemImage: "bookmark.fill",
                accessibilityID: "profile.stat.watchlist"
            )
        }
        .padding(.top, AppSpacing.sm)
    }
}

/// One count tile in the profile stats row.
private struct StatTile: View {
    let value: Int
    let label: Text
    let systemImage: String
    let accessibilityID: String

    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            Label {
                Text(value, format: .number)
                    .font(AppTypography.title)
            } icon: {
                Image(systemName: systemImage)
                    .foregroundStyle(AppColors.brandSecondary)
            }
            label
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(accessibilityID)
    }
}
