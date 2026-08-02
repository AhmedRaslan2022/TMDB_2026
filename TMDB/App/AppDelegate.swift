//
//  AppDelegate.swift
//  TMDB
//
//  Created by Ahmed Raslan on 26/07/2026.
//

import CoreUtilities
import UIKit

/// UIKit application-lifecycle seam for the SwiftUI app. Deliberately thin — the
/// SwiftUI `App` lifecycle still owns the UI (see `TMDBApp`). This exists as the
/// canonical hook for concerns that require the application delegate:
/// push-notification registration, background tasks, third-party SDK bootstrap
/// (none wired yet). Wired in via `@UIApplicationDelegateAdaptor`.
final class AppDelegate: NSObject, UIApplicationDelegate {
    private let logger = AppLogger(category: "Lifecycle")

    func application(
        _: UIApplication,
        didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        logger.info("Application did finish launching")
        return true
    }

    /// Routes each new scene to `SceneDelegate`, so scene-lifecycle hooks are
    /// available while SwiftUI keeps ownership of the window and its content.
    func application(
        _: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options _: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(
            name: "Default Configuration",
            sessionRole: connectingSceneSession.role
        )
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }
}
