import FeatureAuth
import SwiftUI

/// Root switch between the auth gate and the main shell, driven entirely by
/// `AppCoordinator`.
struct RootView: View {
    let coordinator: AppCoordinator

    var body: some View {
        switch coordinator.rootScene {
        case .auth:
            AuthPlaceholderView(onContinue: { coordinator.completeAuthGate() })
        case .main:
            // Replaced by the coordinator-bound tab shell in task 1.6.
            Text("Main shell", comment: "Temporary main scene placeholder")
        }
    }
}

#Preview {
    RootView(coordinator: AppCoordinator())
}
