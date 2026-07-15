import SwiftUI

/// Rounded card surface for list/grid content.
///
/// Stub for Sprint 0 — elevation and context-menu affordances land with the
/// first consuming feature.
public struct CardContainer<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .padding(AppSpacing.lg)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: AppRadius.md))
    }
}

#Preview {
    CardContainer {
        Text("Card content")
    }
    .padding(AppSpacing.lg)
}
