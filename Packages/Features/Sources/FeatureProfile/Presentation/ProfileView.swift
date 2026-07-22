//
//  ProfileView.swift
//  TMDB
//
//  Created by Ahmed Raslan on 17/07/2026.
//

import CoreUI
import SwiftUI

/// The Profile tab: account header (avatar, username, stats) plus entries for
/// settings/about/what's-new and sign-out. Navigation and presentation intent
/// is reported through closures — the coordinator decides what happens.
public struct ProfileView: View {
    @State private var viewModel: ProfileViewModel
    /// Environment name shown as a small badge in debug builds; `nil` hides it.
    private let debugEnvironmentName: String?
    private let onOpenSettings: () -> Void
    private let onShowAbout: () -> Void
    private let onShowWhatsNew: () -> Void
    private let onSignOut: () -> Void

    public init(
        viewModel: ProfileViewModel,
        debugEnvironmentName: String? = nil,
        onOpenSettings: @escaping () -> Void,
        onShowAbout: @escaping () -> Void,
        onShowWhatsNew: @escaping () -> Void,
        onSignOut: @escaping () -> Void
    ) {
        _viewModel = State(initialValue: viewModel)
        self.debugEnvironmentName = debugEnvironmentName
        self.onOpenSettings = onOpenSettings
        self.onShowAbout = onShowAbout
        self.onShowWhatsNew = onShowWhatsNew
        self.onSignOut = onSignOut
    }

    public var body: some View {
        List {
            Section {
                header
            }
            entriesSection
            Section {
                Button(role: .destructive, action: onSignOut) {
                    Text("Sign Out", bundle: .module, comment: "Sign out button")
                }
            } footer: {
                if let debugEnvironmentName {
                    Text(verbatim: "Environment: \(debugEnvironmentName)")
                        .accessibilityIdentifier("profile.environment")
                }
            }
        }
        .navigationTitle(Text("Profile", bundle: .module, comment: "Profile tab title"))
        .task { await viewModel.load() }
    }

    @ViewBuilder
    private var header: some View {
        switch viewModel.state {
        case .loading:
            ProgressView().frame(maxWidth: .infinity)
        case .guest:
            AccountHeaderView(state: .guest, avatarURL: nil)
        case let .loaded(account, stats):
            AccountHeaderView(state: .account(account, stats), avatarURL: viewModel.avatarURL(for: account))
        case let .error(message):
            VStack(spacing: AppSpacing.md) {
                Text(message)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textSecondary)
                Button {
                    Task { await viewModel.load() }
                } label: {
                    Text("Retry", bundle: .module, comment: "Retry loading the profile")
                        .font(AppTypography.label)
                }
                .buttonStyle(.bordered)
                .tint(AppColors.brandSecondary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var entriesSection: some View {
        Section {
            Button(action: onOpenSettings) {
                Label {
                    Text("Settings", bundle: .module, comment: "Open settings button")
                } icon: {
                    Image(systemName: "gearshape")
                }
            }
            Button(action: onShowAbout) {
                Label {
                    Text("About", bundle: .module, comment: "Show about sheet button")
                } icon: {
                    Image(systemName: "info.circle")
                }
            }
            Button(action: onShowWhatsNew) {
                Label {
                    Text("What's New", bundle: .module, comment: "Show what's-new cover button")
                } icon: {
                    Image(systemName: "sparkles")
                }
            }
        }
    }
}

#if DEBUG
    #Preview {
        NavigationStack {
            ProfileView(
                viewModel: ProfileViewModel(
                    repository: PreviewProfileRepository(),
                    imageBaseURL: URL(fileURLWithPath: "/")
                ),
                debugEnvironmentName: "Dev",
                onOpenSettings: {},
                onShowAbout: {},
                onShowWhatsNew: {},
                onSignOut: {}
            )
        }
    }

    private struct PreviewProfileRepository: ProfileRepository {
        func account() async throws -> Account {
            Account(id: 1, username: "ada", name: "Ada Lovelace", gravatarHash: "abc")
        }

        func stats(for _: Int) async throws -> AccountStats {
            AccountStats(favoriteCount: 12, watchlistCount: 5)
        }
    }
#endif
