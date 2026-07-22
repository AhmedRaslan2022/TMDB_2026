// swift-tools-version: 6.0
// By Ahmed Raslan ®
import PackageDescription

let package = Package(
    name: "CoreUtilities",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "CoreUtilities", targets: ["CoreUtilities"]),
    ],
    targets: [
        .target(name: "CoreUtilities"),
    ]
)
