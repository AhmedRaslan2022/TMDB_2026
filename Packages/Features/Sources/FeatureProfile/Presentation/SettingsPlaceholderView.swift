// By Ahmed Raslan ®

import CoreUI
import SwiftUI

/// Destination placeholder for app settings. Replaced in Sprint 5.
public struct SettingsPlaceholderView: View {
    public init() {}

    public var body: some View {
        Text("Settings arrive in Sprint 5.", comment: "Settings placeholder body")
            .font(AppTypography.body)
            .foregroundStyle(AppColors.textSecondary)
            .navigationTitle(Text("Settings", comment: "Settings nav title"))
    }
}

#Preview {
    NavigationStack {
        SettingsPlaceholderView()
    }
}
