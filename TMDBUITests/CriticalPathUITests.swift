//
//  CriticalPathUITests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 22/07/2026.
//

import XCTest

/// Sprint 9 (task 9.2): end-to-end UI coverage of the two critical paths a
/// reviewer checks first — logging in and (un)favoriting — against the Test
/// scheme, driven offline by the `-uitest-stubs` seam so no real auth or
/// network is needed.
final class CriticalPathUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launchStubbedApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-uitest-stubs", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        return app
    }

    /// The primary "Sign in with TMDB" button — the authenticated login branch,
    /// distinct from the guest path — lands in the tab shell. Real TMDB auth
    /// needs web approval, so the stub's LoginUseCase completes the session
    /// offline; this proves the button → VM.logIn() → shell wiring.
    @MainActor
    func testLoginButtonEntersShellFromAuthGate() {
        let app = launchStubbedApp()

        let signIn = app.buttons["Sign in with TMDB"]
        XCTAssertTrue(signIn.waitForExistence(timeout: 5), "Auth gate should show the login button")
        signIn.tap()

        XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 5), "Login should enter the tab shell")
        XCTAssertTrue(
            app.buttons["home.movie.550"].firstMatch.waitForExistence(timeout: 5),
            "The authenticated Home carousel should load"
        )
    }

    /// The *remove* side of favoriting. Toggling the details favorite on then
    /// off returns the button to the un-favorited state and removes the movie
    /// from the shared Favorites store, so the Favorites tab no longer lists it.
    @MainActor
    func testFavoriteToggleOffRemovesFromFavoritesTab() {
        let app = launchStubbedApp()

        app.buttons["Continue as guest"].tap()
        let poster = app.buttons["home.movie.550"].firstMatch
        XCTAssertTrue(poster.waitForExistence(timeout: 5), "Stubbed home carousel should show")
        poster.tap()

        let favorite = app.buttons["details.favorite"]
        XCTAssertTrue(favorite.waitForExistence(timeout: 5), "Details should show a favorite button")

        // Add, then remove — the accessibility value round-trips.
        favorite.tap()
        expectation(for: NSPredicate(format: "value == %@", "Favorited"), evaluatedWith: favorite)
        waitForExpectations(timeout: 5)
        favorite.tap()
        expectation(for: NSPredicate(format: "value == %@", "Not favorited"), evaluatedWith: favorite)
        waitForExpectations(timeout: 5)

        // The Favorites tab reflects the removal — the movie is gone.
        app.tabBars.buttons["Favorites"].tap()
        XCTAssertTrue(
            app.buttons["favorites.movie.550"].firstMatch.waitForNonExistence(timeout: 5),
            "Un-favoriting on details should remove the movie from the Favorites tab"
        )
    }
}
