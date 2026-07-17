// swift-tools-version: 6.0
import PackageDescription

/// Mocks and stubs shared across test targets. Never linked into the app.
let package = Package(
    name: "Shared",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "SharedTestSupport", targets: ["SharedTestSupport"]),
    ],
    dependencies: [
        .package(path: "../Core/CoreModels"),
        .package(path: "../Core/Networking"),
    ],
    targets: [
        .target(
            name: "SharedTestSupport",
            dependencies: [
                .product(name: "CoreModels", package: "CoreModels"),
                .product(name: "Networking", package: "Networking"),
            ]
        ),
    ]
)
