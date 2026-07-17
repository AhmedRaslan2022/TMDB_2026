// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Networking",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "Networking", targets: ["Networking"]),
    ],
    dependencies: [
        .package(path: "../CoreUtilities"),
    ],
    targets: [
        .target(
            name: "Networking",
            dependencies: [
                .product(name: "CoreUtilities", package: "CoreUtilities"),
            ]
        ),
        .testTarget(name: "NetworkingTests", dependencies: ["Networking"]),
    ]
)
