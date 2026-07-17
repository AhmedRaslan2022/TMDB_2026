import CoreUI
import SwiftUI

/// Full-screen cover demonstrating coordinator-driven presentation.
public struct WhatsNewCoverView: View {
    private let onDismiss: () -> Void

    public init(onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
    }

    public var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()
            Text("What's New", comment: "What's-new cover title")
                .font(AppTypography.screenTitle)
            Text("Full-screen cover presented by the coordinator.", comment: "What's-new cover body")
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textSecondary)
            Spacer()
            PrimaryButton("Close", action: onDismiss)
        }
        .padding(AppSpacing.lg)
    }
}

#Preview {
    WhatsNewCoverView(onDismiss: {})
}
