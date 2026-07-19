//
//  TMDBUITests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 14/07/2026.
//

import XCTest

/// Sprint 1 DoD: the auth-gated shell launches, tabs switch, and a
/// coordinator-driven push lands on the destination.
final class TMDBUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testAuthGateTabSwitchAndPushNavigation() {
        let app = XCUIApplication()
        // Real TMDB auth needs web approval and Home needs the network, so
        // run against the offline stub modules (auth + movie lists).
        app.launchArguments += ["-uitest-stubs"]
        app.launch()

        // Auth gate → main shell via the guest path.
        let guestButton = app.buttons["Continue as guest"]
        XCTAssertTrue(guestButton.waitForExistence(timeout: 5), "Auth gate should show first")
        guestButton.tap()

        // Tab shell appears on Home.
        XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 5))

        // Coordinator-driven push from a stubbed Home poster card.
        let firstPoster = app.buttons["home.movie.550"].firstMatch
        XCTAssertTrue(firstPoster.waitForExistence(timeout: 5), "Stubbed home carousel should show")
        firstPoster.tap()
        let detailsTitle = app.staticTexts["details.title"]
        XCTAssertTrue(detailsTitle.waitForExistence(timeout: 5), "Push should land on the real details screen")
        XCTAssertEqual(detailsTitle.label, "UITest Movie 550")
        app.navigationBars.buttons.firstMatch.tap() // back

        // Tab switching.
        app.tabBars.buttons["Profile"].tap()
        XCTAssertTrue(app.buttons["Sign Out"].waitForExistence(timeout: 5))

        // Coordinator-driven sheet.
        app.buttons["About (sheet)"].tap()
        XCTAssertTrue(app.buttons["Done"].waitForExistence(timeout: 5))
        app.buttons["Done"].tap()

        // Sign out returns to the auth gate.
        app.buttons["Sign Out"].tap()
        XCTAssertTrue(guestButton.waitForExistence(timeout: 5), "Sign out should return to auth gate")
    }
}
