//
//  AboutSheetView.swift
//  TMDB
//
//  Created by Ahmed Raslan on 17/07/2026.
//

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
                Text("TMDB Showcase", bundle: .module, comment: "About sheet title")
                    .font(AppTypography.screenTitle)
                Text("Movie data provided by The Movie Database.", bundle: .module, comment: "About sheet attribution")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        onDismiss()
                    } label: {
                        Text("Done", bundle: .module, comment: "Dismiss sheet button")
                    }
                }
            }
        }
    }
}

#Preview {
    AboutSheetView(onDismiss: {})
}
