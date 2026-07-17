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
        app.launch()

        // Auth gate → main shell.
        let continueButton = app.buttons["Continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5), "Auth gate should show first")
        continueButton.tap()

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
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5), "Sign out should return to auth gate")
    }
}
