// swift-tools-version: 6.0
import PackageDescription

/// Features depend on Core only — a feature target must NEVER depend on
/// another feature target. Cross-feature navigation happens through
/// coordinators in the app target.
let coreProducts: [Target.Dependency] = [
    .product(name: "CoreModels", package: "Core"),
    .product(name: "CoreUtilities", package: "Core"),
    .product(name: "CoreNetworking", package: "Core"),
    .product(name: "CoreStorage", package: "Core"),
    .product(name: "CoreUI", package: "Core"),
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
        .package(path: "../Core"),
    ],
    targets: featureNames.map { .target(name: $0, dependencies: coreProducts) }
)
