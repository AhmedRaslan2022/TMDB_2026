//
//  TMDBApp.swift
//  TMDB
//
//  Created by Ahmed Raslan on 14/07/2026.
//

import CoreUI
import SwiftData
import SwiftUI

/// App entry point. The app target only composes modules; all functionality
/// lives in the SPM packages under `Packages/`.
@main
struct TMDBApp: App {
    @State private var container = AppContainer()

    var body: some Scene {
        WindowGroup {
            RootView(container: container)
                .environment(\.imageCache, container.imageCache)
            #if DEBUG
                .task {
                    await DebugSmokeCheck.run(
                        apiClient: container.apiClient,
                        environment: container.environment
                    )
                }
            #endif
        }
        .modelContainer(container.modelContainer)
    }
}
