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
        .package(path: "../CoreKit"),
        .package(path: "../../Shared"),
        // The ONLY third-party dependency in the project, and test-only:
        // snapshot testing (task 8.6) needs a reference-image diff engine that
        // isn't worth hand-rolling. Never linked into shipping code.
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.17.0"),
    ],
    targets: [
        .target(
            name: "CoreUI",
            dependencies: [
                .product(name: "CoreUtilities", package: "CoreKit"),
            ],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "CoreUITests",
            dependencies: [
                "CoreUI",
                .product(name: "SharedTestSupport", package: "Shared"),
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
            ]
        ),
    ]
)
