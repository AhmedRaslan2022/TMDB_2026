// swift-tools-version: 6.0
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
    ],
    targets: [
        .target(
            name: "CoreUI",
            dependencies: [
                .product(name: "CoreUtilities", package: "CoreUtilities"),
            ]
        ),
    ]
)
