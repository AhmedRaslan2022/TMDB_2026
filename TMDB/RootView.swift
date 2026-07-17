//
//  RootView.swift
//  TMDB
//
//  Created by Ahmed Raslan on 15/07/2026.
//

import FeatureAuth
import FeatureProfile
import SwiftUI

/// Root switch between the auth gate and the main shell, driven entirely by
/// `AppCoordinator`. Modal presentation is attached here so any scene can
/// present coordinator-owned sheets and covers.
struct RootView: View {
    @Bindable var coordinator: AppCoordinator
    /// Built once from the coordinator; survives auth↔main switches so the
    /// screen's loading/error state isn't reset by re-renders.
    @State private var authViewModel: AuthViewModel

    init(coordinator: AppCoordinator) {
        _coordinator = Bindable(coordinator)
        _authViewModel = State(initialValue: coordinator.makeAuthViewModel())
    }

    var body: some View {
        content
            .task { await coordinator.restoreSession() }
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
            AuthView(viewModel: authViewModel)
        case .main:
            MainTabView(coordinator: coordinator)
        }
    }
}

#if DEBUG
    #Preview {
        RootView(coordinator: AppCoordinator(auth: .stub))
    }
#endif
