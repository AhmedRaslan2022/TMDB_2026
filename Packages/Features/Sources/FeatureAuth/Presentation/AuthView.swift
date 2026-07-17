//
//  AuthView.swift
//  TMDB
//
//  Created by Ahmed Raslan on 17/07/2026.
//

import CoreUI
import SwiftUI

/// The auth gate: sign in with a TMDB account or continue as a guest. All
/// business logic lives in `AuthViewModel`; this view only renders state and
/// forwards taps.
public struct AuthView: View {
    private let viewModel: AuthViewModel

    public init(viewModel: AuthViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()
            header
            Spacer()
            errorMessage
            actions
        }
        .padding(AppSpacing.lg)
        .animation(.default, value: isLoading)
    }

    private var isLoading: Bool {
        viewModel.state == .loading
    }

    private var header: some View {
        VStack(spacing: AppSpacing.md) {
            Text("TMDB", comment: "App name on the auth screen")
                .font(AppTypography.screenTitle)
                .foregroundStyle(AppColors.brandSecondary)

            Text(
                "Discover movies, build your watchlist, and rate what you watch.",
                comment: "Auth screen value proposition"
            )
            .font(AppTypography.body)
            .foregroundStyle(AppColors.textSecondary)
            .multilineTextAlignment(.center)
        }
    }

    @ViewBuilder
    private var errorMessage: some View {
        if case let .error(message) = viewModel.state {
            Text(message)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.error)
                .multilineTextAlignment(.center)
                .transition(.opacity)
        }
    }

    private var actions: some View {
        VStack(spacing: AppSpacing.md) {
            PrimaryButton("Sign in with TMDB") {
                Task { await viewModel.logIn() }
            }

            Button {
                Task { await viewModel.continueAsGuest() }
            } label: {
                Text("Continue as guest", comment: "Guest login button")
                    .font(AppTypography.title)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
            }
            .buttonStyle(.bordered)
            .tint(AppColors.brandSecondary)
        }
        .disabled(isLoading)
        .overlay {
            if isLoading {
                ProgressView()
                    .controlSize(.large)
                    .tint(AppColors.brandSecondary)
            }
        }
    }
}

#Preview {
    AuthView(
        viewModel: AuthViewModel(
            loginUseCase: PreviewLoginUseCase(),
            createGuestSessionUseCase: PreviewGuestUseCase(),
            onAuthenticated: { _ in }
        )
    )
}

private struct PreviewLoginUseCase: LoginUseCase {
    func execute() async throws -> AuthSession {
        .authenticated(sessionID: "preview")
    }
}

private struct PreviewGuestUseCase: CreateGuestSessionUseCase {
    func execute() async throws -> AuthSession {
        .guest(sessionID: "preview")
    }
}
