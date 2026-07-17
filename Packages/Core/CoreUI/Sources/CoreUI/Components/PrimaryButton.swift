import SwiftUI

/// Filled brand-colored call-to-action button.
///
/// Stub for Sprint 0 — loading/disabled states and haptics land with the
/// first consuming feature.
public struct PrimaryButton: View {
    private let title: LocalizedStringKey
    private let action: () -> Void

    public init(_ title: LocalizedStringKey, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTypography.title)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.md)
        }
        .buttonStyle(.borderedProminent)
        .tint(AppColors.brandSecondary)
    }
}

#Preview {
    PrimaryButton("Sign In") {}
        .padding(AppSpacing.lg)
}
