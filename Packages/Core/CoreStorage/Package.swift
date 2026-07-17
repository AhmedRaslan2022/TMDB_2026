// swift-tools-version: 6.0
// By Ahmed Raslan ®
import PackageDescription

/// Storage is split into three independent products so consumers link only
/// the persistence mechanism they actually use.
let package = Package(
    name: "CoreStorage",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "KeychainStorage", targets: ["KeychainStorage"]),
        .library(name: "SwiftDataStorage", targets: ["SwiftDataStorage"]),
        .library(name: "UserDefaultsStorage", targets: ["UserDefaultsStorage"]),
    ],
    dependencies: [
        .package(path: "../CoreUtilities"),
    ],
    targets: [
        .target(
            name: "KeychainStorage",
            dependencies: [
                .product(name: "CoreUtilities", package: "CoreUtilities"),
            ]
        ),
        .target(
            name: "SwiftDataStorage",
            dependencies: [
                .product(name: "CoreUtilities", package: "CoreUtilities"),
            ]
        ),
        .target(
            name: "UserDefaultsStorage",
            dependencies: [
                .product(name: "CoreUtilities", package: "CoreUtilities"),
            ]
        ),
        .testTarget(name: "KeychainStorageTests", dependencies: ["KeychainStorage"]),
        .testTarget(name: "SwiftDataStorageTests", dependencies: ["SwiftDataStorage"]),
        .testTarget(name: "UserDefaultsStorageTests", dependencies: ["UserDefaultsStorage"]),
    ]
)
