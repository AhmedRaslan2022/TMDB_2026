import CoreUI
import SwiftUI

/// Temporary auth gate. Replaced by the real TMDB login flow in Sprint 2.
/// Navigation is owned by the coordinator — this view only reports intent.
public struct AuthPlaceholderView: View {
    private let onContinue: () -> Void

    public init(onContinue: @escaping () -> Void) {
        self.onContinue = onContinue
    }

    public var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

            Text("TMDB", comment: "App name on the auth screen")
                .font(AppTypography.screenTitle)
                .foregroundStyle(AppColors.brandSecondary)

            Text("Sign-in arrives in Sprint 2.", comment: "Auth placeholder subtitle")
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textSecondary)

            Spacer()

            PrimaryButton("Continue", action: onContinue)
        }
        .padding(AppSpacing.lg)
    }
}

#Preview {
    AuthPlaceholderView(onContinue: {})
}
