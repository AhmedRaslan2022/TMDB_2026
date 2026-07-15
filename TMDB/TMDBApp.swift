import SwiftUI

/// Composition root. The app target only wires modules together;
/// all functionality lives in the SPM packages under `Packages/`.
@main
struct TMDBApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
