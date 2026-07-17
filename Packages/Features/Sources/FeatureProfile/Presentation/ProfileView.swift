import CoreUI
import SwiftUI

/// Profile tab placeholder. Account details land in Sprint 5.
/// Navigation and presentation intent is reported through closures — the
/// coordinator decides what happens.
public struct ProfileView: View {
    private let onOpenSettings: () -> Void
    private let onShowAbout: () -> Void
    private let onShowWhatsNew: () -> Void
    private let onSignOut: () -> Void

    public init(
        onOpenSettings: @escaping () -> Void,
        onShowAbout: @escaping () -> Void,
        onShowWhatsNew: @escaping () -> Void,
        onSignOut: @escaping () -> Void
    ) {
        self.onOpenSettings = onOpenSettings
        self.onShowAbout = onShowAbout
        self.onShowWhatsNew = onShowWhatsNew
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

            Button {
                onShowAbout()
            } label: {
                Text("About (sheet)", comment: "Show about sheet button")
            }

            Button {
                onShowWhatsNew()
            } label: {
                Text("What's New (cover)", comment: "Show what's-new cover button")
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
        ProfileView(onOpenSettings: {}, onShowAbout: {}, onShowWhatsNew: {}, onSignOut: {})
    }
}
