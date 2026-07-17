// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CoreModels",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "CoreModels", targets: ["CoreModels"]),
    ],
    targets: [
        .target(name: "CoreModels"),
    ]
)
