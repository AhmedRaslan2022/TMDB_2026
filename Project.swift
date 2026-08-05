//
//  Project.swift
//  TMDB
//
//  Created by Ahmed Raslan on 03/08/2026.
//

import ProjectDescription

// MARK: - Environments

/// The four environments are build configurations, and each keeps its existing
/// xcconfig as the source of truth for env-specific settings (bundle-id suffix,
/// app icon, optimization level, API base URLs). Tuist owns the project
/// structure; the xcconfigs still own the values, so `Configs/Secrets.xcconfig`
/// stays the only place a real token lives.
private let configurations: [Configuration] = [
    .debug(name: "Dev", xcconfig: "Enviroments/Dev.xcconfig"),
    .release(name: "Staging", xcconfig: "Enviroments/Staging.xcconfig"),
    .debug(name: "Test", xcconfig: "Enviroments/Test.xcconfig"),
    .release(name: "Live", xcconfig: "Enviroments/Live.xcconfig"),
]

private let environmentNames = ["Dev", "Staging", "Test", "Live"]

// MARK: - Shared settings

/// Settings that used to live on the app target in project.pbxproj. Values that
/// vary per environment are deliberately absent — those come from the xcconfigs.
///
/// `PRODUCT_BUNDLE_IDENTIFIER` is the exception: Tuist always writes the
/// target's `bundleId`, and a target-level setting outranks the project's
/// xcconfig, so the id is composed from two xcconfig variables instead of being
/// hard-coded. That keeps the per-environment suffix working.
private let appSettings: SettingsDictionary = [
    "ASSETCATALOG_COMPILER_APPICON_NAME": "$(APP_ICON_NAME)",
    "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "AccentColor",
    "CODE_SIGN_STYLE": "Automatic",
    "CURRENT_PROJECT_VERSION": "1",
    "DEVELOPMENT_TEAM": "R6RXWLTM3U",
    "ENABLE_PREVIEWS": "YES",
    "GENERATE_INFOPLIST_FILE": "YES",
    "INFOPLIST_KEY_CFBundleDisplayName": "TMDB",
    "INFOPLIST_KEY_UIApplicationSceneManifest_Generation": "YES",
    "INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents": "YES",
    "INFOPLIST_KEY_UILaunchScreen_Generation": "NO",
    "INFOPLIST_KEY_UISupportedInterfaceOrientations": """
    UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight \
    UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown
    """,
    "LD_RUNPATH_SEARCH_PATHS": ["$(inherited)", "@executable_path/Frameworks"],
    "MARKETING_VERSION": "$(APP_MARKETING_VERSION)",
    "STRING_CATALOG_GENERATE_SYMBOLS": "YES",
    "SWIFT_APPROACHABLE_CONCURRENCY": "YES",
    "SWIFT_DEFAULT_ACTOR_ISOLATION": "MainActor",
    "SWIFT_EMIT_LOC_STRINGS": "YES",
    "SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY": "YES",
    "SWIFT_VERSION": "5.0",
    "TARGETED_DEVICE_FAMILY": "1,2",
]

private let testTargetSettings: SettingsDictionary = [
    "CODE_SIGN_STYLE": "Automatic",
    "CURRENT_PROJECT_VERSION": "1",
    // Present on all eight test build configs so the suites can also run on a
    // physical device — without it, device signing fails.
    "DEVELOPMENT_TEAM": "R6RXWLTM3U",
    "GENERATE_INFOPLIST_FILE": "YES",
    "MARKETING_VERSION": "$(APP_MARKETING_VERSION)",
    "SWIFT_VERSION": "5.0",
    "TARGETED_DEVICE_FAMILY": "1,2",
]

// MARK: - Local packages

private let localPackages: [Package] = [
    .local(path: "Packages/Core/CoreKit"),
    .local(path: "Packages/Core/Networking"),
    .local(path: "Packages/Core/CoreStorage"),
    .local(path: "Packages/Core/CoreUI"),
    .local(path: "Packages/Features"),
    .local(path: "Packages/Shared"),
]

/// Every product the app links. `UserDefaultsStorage` is listed explicitly:
/// the hand-written project omitted it and `import UserDefaultsStorage` only
/// compiled because Xcode makes sibling SPM modules implicitly visible.
private let appPackageProducts = [
    "CoreModels",
    "CoreUtilities",
    "CoreEnvironment",
    "Networking",
    "KeychainStorage",
    "SwiftDataStorage",
    "UserDefaultsStorage",
    "CoreUI",
    "FeatureAuth",
    "FeatureFavorites",
    "FeatureHome",
    "FeatureMovieDetails",
    "FeatureOnboarding",
    "FeaturePerson",
    "FeatureProfile",
    "FeatureSearch",
    "FeatureTV",
]

// MARK: - Schemes

/// One scheme per environment, matching the names CI and Fastlane already use
/// (`TMDB-Test` is what `xcodebuild test` runs).
private func scheme(for environment: String) -> Scheme {
    .scheme(
        name: "TMDB-\(environment)",
        shared: true,
        buildAction: .buildAction(targets: ["TMDB"]),
        // Parallelization is not cosmetic: each UI test needs a freshly
        // installed app. Run them serially on one simulator and the persisted
        // session from an earlier test carries over, so later tests boot
        // straight into the shell and never see the auth gate.
        testAction: .targets(
            [
                .testableTarget(target: "TMDBTests", parallelization: .enabled),
                .testableTarget(target: "TMDBUITests", parallelization: .enabled),
            ],
            configuration: ConfigurationName.configuration(environment)
        ),
        runAction: .runAction(configuration: ConfigurationName.configuration(environment)),
        archiveAction: .archiveAction(configuration: ConfigurationName.configuration(environment)),
        profileAction: .profileAction(configuration: ConfigurationName.configuration(environment)),
        analyzeAction: .analyzeAction(configuration: ConfigurationName.configuration(environment))
    )
}

// MARK: - Project

let project = Project(
    name: "TMDB",
    organizationName: "Ahmed Raslan",
    options: .options(
        automaticSchemesOptions: .disabled,
        // English is the source language of every String Catalog. Without this
        // the app ships only the translated `ar.lproj`, so a launch forced to
        // English silently falls back to Arabic.
        developmentRegion: "en",
        disableBundleAccessors: false,
        disableSynthesizedResourceAccessors: true
    ),
    packages: localPackages,
    // Tuist's "recommended" defaults are older than Xcode's current template
    // defaults, so pin the few that the hand-written project relied on.
    settings: .settings(
        base: [
            "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS": "YES",
            "CLANG_CXX_LANGUAGE_STANDARD": "gnu++20",
            "CODE_SIGN_IDENTITY": "Apple Development",
        ],
        configurations: configurations
    ),
    targets: [
        .target(
            name: "TMDB",
            destinations: .iOS,
            product: .app,
            bundleId: "$(APP_BUNDLE_ID_BASE)$(APP_BUNDLE_ID_SUFFIX)",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .file(path: "TMDB/Info.plist"),
            sources: [
                "TMDB/**/*.swift",
                // Lives beside the UI tests but compiles into the app: the
                // stub seam is read by AppContainer behind `#if DEBUG`.
                "TMDBUITests/UITestStubs.swift",
            ],
            resources: [
                "TMDB/Assets.xcassets",
                "TMDB/LaunchScreen.storyboard",
                "TMDB/**/*.xcstrings",
            ],
            dependencies: appPackageProducts.map { .package(product: $0) },
            settings: .settings(base: appSettings)
        ),
        .target(
            name: "TMDBTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "$(APP_BUNDLE_ID_BASE)Tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["TMDBTests/**/*.swift"],
            dependencies: [.target(name: "TMDB")],
            settings: .settings(base: testTargetSettings)
        ),
        .target(
            name: "TMDBUITests",
            destinations: .iOS,
            product: .uiTests,
            bundleId: "$(APP_BUNDLE_ID_BASE)UITests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: [
                .glob("TMDBUITests/**/*.swift", excluding: ["TMDBUITests/UITestStubs.swift"]),
            ],
            dependencies: [.target(name: "TMDB")],
            settings: .settings(base: testTargetSettings)
        ),
    ],
    schemes: environmentNames.map(scheme(for:))
)
