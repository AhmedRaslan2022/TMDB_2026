// swift-tools-version: 6.0
// By Ahmed Raslan ®
import PackageDescription

let package = Package(
    name: "CoreUI",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "CoreUI", targets: ["CoreUI"]),
    ],
    dependencies: [
        .package(path: "../CoreUtilities"),
        .package(path: "../../Shared"),
    ],
    targets: [
        .target(
            name: "CoreUI",
            dependencies: [
                .product(name: "CoreUtilities", package: "CoreUtilities"),
            ]
        ),
        .testTarget(
            name: "CoreUITests",
            dependencies: [
                "CoreUI",
                .product(name: "SharedTestSupport", package: "Shared"),
            ]
        ),
    ]
)
