// swift-tools-version: 6.0
import PackageDescription

/// Features depend on Core packages only — a feature target must NEVER depend
/// on another feature target. Cross-feature navigation happens through
/// coordinators in the app target.
let coreProducts: [Target.Dependency] = [
    .product(name: "CoreModels", package: "CoreModels"),
    .product(name: "CoreUtilities", package: "CoreUtilities"),
    .product(name: "Networking", package: "Networking"),
    .product(name: "CoreStorage", package: "CoreStorage"),
    .product(name: "CoreUI", package: "CoreUI"),
]

let featureNames = [
    "FeatureAuth",
    "FeatureHome",
    "FeatureMovieDetails",
    "FeatureSearch",
    "FeatureFavorites",
    "FeatureProfile",
]

let package = Package(
    name: "Features",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: featureNames.map { .library(name: $0, targets: [$0]) },
    dependencies: [
        .package(path: "../Core/CoreModels"),
        .package(path: "../Core/CoreUtilities"),
        .package(path: "../Core/Networking"),
        .package(path: "../Core/CoreStorage"),
        .package(path: "../Core/CoreUI"),
    ],
    targets: featureNames.map { .target(name: $0, dependencies: coreProducts) }
)
