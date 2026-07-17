//
//  TMDBApp.swift
//  TMDB
//
//  Created by Ahmed Raslan on 14/07/2026.
//

import SwiftData
import SwiftUI

/// App entry point. The app target only composes modules; all functionality
/// lives in the SPM packages under `Packages/`.
@main
struct TMDBApp: App {
    @State private var container = AppContainer()
    @State private var coordinator = AppCoordinator()

    var body: some Scene {
        WindowGroup {
            RootView(coordinator: coordinator)
            #if DEBUG
                .task {
                    await DebugSmokeCheck.run(
                        apiClient: container.apiClient,
                        secureStorage: container.secureStorage,
                        environment: container.environment
                    )
                }
            #endif
        }
        .modelContainer(container.modelContainer)
    }
}
