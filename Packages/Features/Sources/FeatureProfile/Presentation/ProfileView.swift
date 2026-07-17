import CoreUI
import SwiftUI

/// Profile tab placeholder. Account details land in Sprint 5.
public struct ProfileView: View {
    private let onOpenSettings: () -> Void
    private let onSignOut: () -> Void

    public init(onOpenSettings: @escaping () -> Void, onSignOut: @escaping () -> Void) {
        self.onOpenSettings = onOpenSettings
        self.onSignOut = onSignOut
    }

    public var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Text("Profile lands in Sprint 5.", comment: "Profile placeholder body")
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textSecondary)

            Button {
                onOpenSettings()
            } label: {
                Text("Settings", comment: "Open settings button")
            }

            Button(role: .destructive) {
                onSignOut()
            } label: {
                Text("Sign Out", comment: "Sign out button")
            }
        }
        .navigationTitle(Text("Profile", comment: "Profile tab title"))
    }
}

#Preview {
    NavigationStack {
        ProfileView(onOpenSettings: {}, onSignOut: {})
    }
}
