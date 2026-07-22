// swift-tools-version: 6.0
// By Ahmed Raslan ®
import PackageDescription

let package = Package(
    name: "CoreEnvironment",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "CoreEnvironment", targets: ["CoreEnvironment"]),
    ],
    dependencies: [
        .package(path: "../CoreUtilities"),
    ],
    targets: [
        .target(
            name: "CoreEnvironment",
            dependencies: [
                .product(name: "CoreUtilities", package: "CoreUtilities"),
            ]
        ),
        .testTarget(name: "CoreEnvironmentTests", dependencies: ["CoreEnvironment"]),
    ]
)
