//
//  SceneDelegate.swift
//  TMDB
//
//  Created by Ahmed Raslan on 26/07/2026.
//

import CoreUtilities
import UIKit

/// UIKit scene-lifecycle seam. SwiftUI owns the window and its content — this
/// intentionally does NOT create a `UIWindow`; it only observes the scene
/// lifecycle and is the place to add scene-scoped concerns later (home-screen
/// quick actions, hand-off / `NSUserActivity`, external displays). Deep links
/// keep using SwiftUI's `.onOpenURL` in `RootView`.
final class SceneDelegate: NSObject, UIWindowSceneDelegate {
    private let logger = AppLogger(category: "Lifecycle")

    func scene(
        _: UIScene,
        willConnectTo _: UISceneSession,
        options _: UIScene.ConnectionOptions
    ) {
        logger.info("Scene will connect")
    }

    func sceneDidBecomeActive(_: UIScene) {
        logger.info("Scene did become active")
    }

    func sceneWillResignActive(_: UIScene) {
        logger.info("Scene will resign active")
    }

    func sceneWillEnterForeground(_: UIScene) {
        logger.info("Scene will enter foreground")
    }

    func sceneDidEnterBackground(_: UIScene) {
        logger.info("Scene did enter background")
    }
}
