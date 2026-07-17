// By Ahmed Raslan ®

import CoreUI
import SwiftUI

/// Sheet demonstrating coordinator-driven modal presentation. Gains real
/// content alongside settings in Sprint 5.
public struct AboutSheetView: View {
    private let onDismiss: () -> Void

    public init(onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.md) {
                Text("TMDB Showcase", comment: "About sheet title")
                    .font(AppTypography.screenTitle)
                Text("Movie data provided by The Movie Database.", comment: "About sheet attribution")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        onDismiss()
                    } label: {
                        Text("Done", comment: "Dismiss sheet button")
                    }
                }
            }
        }
    }
}

#Preview {
    AboutSheetView(onDismiss: {})
}
