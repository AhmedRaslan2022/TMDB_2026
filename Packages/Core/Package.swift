// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Core",
    defaultLocalization: "en",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "CoreModels", targets: ["CoreModels"]),
        .library(name: "CoreUtilities", targets: ["CoreUtilities"]),
        .library(name: "CoreEnvironment", targets: ["CoreEnvironment"]),
        .library(name: "CoreNetworking", targets: ["CoreNetworking"]),
        .library(name: "CoreStorage", targets: ["CoreStorage"]),
        .library(name: "CoreUI", targets: ["CoreUI"]),
    ],
    targets: [
        .target(name: "CoreModels"),
        .target(name: "CoreUtilities"),
        .target(name: "CoreEnvironment", dependencies: ["CoreUtilities"]),
        .target(name: "CoreNetworking", dependencies: ["CoreUtilities"]),
        .target(name: "CoreStorage", dependencies: ["CoreUtilities"]),
        .target(name: "CoreUI", dependencies: ["CoreUtilities"]),
        .testTarget(name: "CoreEnvironmentTests", dependencies: ["CoreEnvironment"]),
    ]
)
