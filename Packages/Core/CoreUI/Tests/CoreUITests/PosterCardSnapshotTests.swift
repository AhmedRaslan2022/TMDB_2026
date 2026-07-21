//
//  PosterCardSnapshotTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 21/07/2026.
//

#if os(iOS)
    import SnapshotTesting
    import SwiftUI
    import XCTest
    @testable import CoreUI

    /// Snapshot coverage for the flagship shared component across the axes
    /// Sprint 8 cares about — light/dark, LTR/RTL, and Dynamic Type (task 8.6).
    ///
    /// iOS-only (traits/`@ScaledMetric` need UIKit), so the macOS `swift test`
    /// path skips this file. RUN on the simulator from the package directory:
    ///   `xcodebuild test -scheme CoreUI -destination 'platform=iOS Simulator,…'`
    /// Any future CI must use that invocation — a `swift test`-only CI would
    /// silently skip these. Reference images in `__Snapshots__/` are
    /// renderer/OS-specific; re-record via `record: .all` in `invokeTest` below.
    @MainActor
    final class PosterCardSnapshotTests: XCTestCase {
        /// Flip to `.all` locally to re-record references, then set back to `.missing`.
        override func invokeTest() {
            withSnapshotTesting(record: .missing) { super.invokeTest() }
        }

        private var card: some View {
            PosterCard(title: "Fight Club", posterURL: nil, rating: 8.4, onSelect: {})
                .padding()
                .background(Color(.systemBackground))
        }

        func testLight() {
            assertSnapshot(of: card, as: .image(layout: .sizeThatFits, traits: .init(userInterfaceStyle: .light)))
        }

        func testDark() {
            assertSnapshot(of: card, as: .image(layout: .sizeThatFits, traits: .init(userInterfaceStyle: .dark)))
        }

        func testRightToLeft() {
            assertSnapshot(of: card, as: .image(layout: .sizeThatFits, traits: .init(layoutDirection: .rightToLeft)))
        }

        func testLargeDynamicType() {
            // Apply the size to the VIEW (not only via `traits:`) so the
            // `sizeThatFits` measure pass and the render pass see the same
            // scaled metrics — otherwise the canvas is sized from unscaled
            // metrics and the scaled content clips.
            assertSnapshot(
                of: card.dynamicTypeSize(.accessibility3),
                as: .image(layout: .sizeThatFits)
            )
        }
    }
#endif
