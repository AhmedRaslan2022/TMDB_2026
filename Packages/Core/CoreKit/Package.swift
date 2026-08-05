// swift-tools-version: 6.0
// By Ahmed Raslan ®
import PackageDescription

/// The foundation layer, shipped as one package with a target per module.
///
/// `CoreModels`, `CoreUtilities` and `CoreEnvironment` used to be three
/// separate packages. They are small, versioned together, and always resolved
/// as a unit, so a single package with three targets removes two manifests and
/// two resolution roots. Each target is still exported as its own product, so
/// consumers depend only on the module they use and the layering stays
/// explicit: `CoreModels` is standalone, `CoreEnvironment` builds on
/// `CoreUtilities`.
let package = Package(
    name: "CoreKit",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "CoreModels", targets: ["CoreModels"]),
        .library(name: "CoreUtilities", targets: ["CoreUtilities"]),
        .library(name: "CoreEnvironment", targets: ["CoreEnvironment"]),
    ],
    targets: [
        .target(name: "CoreModels"),
        .target(name: "CoreUtilities"),
        .target(name: "CoreEnvironment", dependencies: ["CoreUtilities"]),
        .testTarget(name: "CoreModelsTests", dependencies: ["CoreModels"]),
        .testTarget(name: "CoreEnvironmentTests", dependencies: ["CoreEnvironment"]),
    ]
)
