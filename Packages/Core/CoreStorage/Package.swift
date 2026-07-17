// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CoreStorage",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "CoreStorage", targets: ["CoreStorage"]),
    ],
    dependencies: [
        .package(path: "../CoreUtilities"),
    ],
    targets: [
        .target(
            name: "CoreStorage",
            dependencies: [
                .product(name: "CoreUtilities", package: "CoreUtilities"),
            ]
        ),
        .testTarget(name: "CoreStorageTests", dependencies: ["CoreStorage"]),
    ]
)
