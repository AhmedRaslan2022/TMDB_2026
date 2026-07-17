// By Ahmed Raslan ®

import FeatureAuth
import FeatureProfile
import SwiftUI

/// Root switch between the auth gate and the main shell, driven entirely by
/// `AppCoordinator`. Modal presentation is attached here so any scene can
/// present coordinator-owned sheets and covers.
struct RootView: View {
    @Bindable var coordinator: AppCoordinator

    var body: some View {
        content
            .sheet(item: $coordinator.presentedSheet) { sheet in
                switch sheet {
                case .about:
                    AboutSheetView(onDismiss: { coordinator.dismissModal() })
                }
            }
            .fullScreenCover(item: $coordinator.presentedFullScreenCover) { cover in
                switch cover {
                case .whatsNew:
                    WhatsNewCoverView(onDismiss: { coordinator.dismissModal() })
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        switch coordinator.rootScene {
        case .auth:
            AuthPlaceholderView(onContinue: { coordinator.completeAuthGate() })
        case .main:
            MainTabView(coordinator: coordinator)
        }
    }
}

#Preview {
    RootView(coordinator: AppCoordinator())
}
