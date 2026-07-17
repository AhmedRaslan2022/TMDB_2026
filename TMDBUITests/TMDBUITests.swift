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
        // Real TMDB auth needs web approval / network, so bypass it with the
        // inert stub module — the guest path then enters the shell offline.
        app.launchArguments += ["-uitest-auth-bypass"]
        app.launch()

        // Auth gate → main shell via the guest path.
        let guestButton = app.buttons["Continue as guest"]
        XCTAssertTrue(guestButton.waitForExistence(timeout: 5), "Auth gate should show first")
        guestButton.tap()

        // Tab shell appears on Home.
        XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 5))

        // Coordinator-driven push from Home.
        app.buttons["Open a movie (test push)"].tap()
        XCTAssertTrue(app.staticTexts["movieID: 550"].waitForExistence(timeout: 5), "Push should land on details")
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
