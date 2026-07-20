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

        // Tab switching — Profile shows the stubbed account.
        app.tabBars.buttons["Profile"].tap()
        XCTAssertTrue(app.buttons["Sign Out"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["profile.username"].waitForExistence(timeout: 5), "Profile shows the account")
        XCTAssertEqual(app.staticTexts["profile.username"].label, "UI Tester")
        XCTAssertTrue(app.otherElements["profile.stat.favorites"].exists || app.staticTexts["Favorites"].exists)

        // Coordinator-driven sheet.
        app.buttons["About"].tap()
        XCTAssertTrue(app.buttons["Done"].waitForExistence(timeout: 5))
        app.buttons["Done"].tap()

        // Sign out returns to the auth gate.
        app.buttons["Sign Out"].tap()
        XCTAssertTrue(guestButton.waitForExistence(timeout: 5), "Sign out should return to auth gate")
    }

    @MainActor
    func testSearchToDetailsFavoriteAndFavoritesTab() {
        let app = XCUIApplication()
        app.launchArguments += ["-uitest-stubs"]
        app.launch()

        app.buttons["Continue as guest"].tap()
        app.tabBars.buttons["Search"].tap()

        // Type into the search field; the stubbed use case returns results.
        let field = app.searchFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5), "Search field should show")
        field.tap()
        field.typeText("dune")

        // A stubbed result card appears and pushes to details.
        let result = app.buttons["search.movie.700"].firstMatch
        XCTAssertTrue(result.waitForExistence(timeout: 5), "Debounced search should show results")
        result.tap()
        XCTAssertTrue(
            app.staticTexts["details.title"].waitForExistence(timeout: 5),
            "Tapping a result should push details"
        )

        // Optimistic favorite toggle flips the button's accessibility value.
        let favorite = app.buttons["details.favorite"]
        XCTAssertTrue(favorite.waitForExistence(timeout: 5), "Details should show a favorite button")
        XCTAssertEqual(favorite.value as? String, "Not favorited")
        favorite.tap()
        expectation(for: NSPredicate(format: "value == %@", "Favorited"), evaluatedWith: favorite)
        waitForExpectations(timeout: 5)

        // Watchlist toggle (second synced collection) flips independently.
        let watchlist = app.buttons["details.watchlist"]
        XCTAssertEqual(watchlist.value as? String, "Not on watchlist")
        watchlist.tap()
        expectation(for: NSPredicate(format: "value == %@", "On watchlist"), evaluatedWith: watchlist)
        waitForExpectations(timeout: 5)

        // Rating: tapping the 4th star writes an optimistic 8/10.
        let ratingControl = app.otherElements["details.rating"]
        XCTAssertTrue(ratingControl.waitForExistence(timeout: 5), "Details should show the user rating control")
        XCTAssertEqual(ratingControl.value as? String, "Not rated")
        app.buttons["details.rating.star.4"].tap()
        expectation(for: NSPredicate(format: "value == %@", "8 out of 10"), evaluatedWith: ratingControl)
        waitForExpectations(timeout: 5)

        // The favorited movie appears on the Favorites tab (shared store).
        app.tabBars.buttons["Favorites"].tap()
        XCTAssertTrue(
            app.buttons["favorites.movie.700"].firstMatch.waitForExistence(timeout: 5),
            "Favoriting on details should surface the movie in the Favorites tab"
        )
    }

    @MainActor
    func testDiscoverFiltersReturnResults() {
        let app = XCUIApplication()
        app.launchArguments += ["-uitest-stubs"]
        app.launch()

        app.buttons["Continue as guest"].tap()
        app.tabBars.buttons["Search"].tap()

        // Open the advanced-search (Discover) screen from the search toolbar.
        let filters = app.buttons["search.discover"]
        XCTAssertTrue(filters.waitForExistence(timeout: 5), "Search should offer a Filters entry")
        filters.tap()

        // The default browse shows stubbed results (base id 900).
        XCTAssertTrue(
            app.buttons["discover.movie.900"].firstMatch.waitForExistence(timeout: 5),
            "Discover should load a default result set"
        )

        // Toggling the Action genre (id 28) shifts the stubbed result set (base 928).
        app.buttons["discover.genre.28"].tap()
        XCTAssertTrue(
            app.buttons["discover.movie.928"].firstMatch.waitForExistence(timeout: 5),
            "A genre filter should change the results"
        )

        // Tapping a result pushes to details.
        app.buttons["discover.movie.928"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["details.title"].waitForExistence(timeout: 5))
    }
}
