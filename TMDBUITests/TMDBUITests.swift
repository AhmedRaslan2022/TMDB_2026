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
        app.launchArguments += ["-uitest-stubs", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
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
        app.launchArguments += ["-uitest-stubs", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
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
    func testCastToPersonToTitleDeepNavigation() {
        let app = XCUIApplication()
        app.launchArguments += ["-uitest-stubs", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()

        app.buttons["Continue as guest"].tap()

        // Home → a movie's details.
        let poster = app.buttons["home.movie.550"].firstMatch
        XCTAssertTrue(poster.waitForExistence(timeout: 5))
        poster.tap()
        XCTAssertTrue(app.staticTexts["details.title"].waitForExistence(timeout: 5))

        // Tap the cast member → person screen.
        let castMember = app.buttons["details.cast.287"]
        XCTAssertTrue(castMember.waitForExistence(timeout: 5), "Details should show a tappable cast member")
        castMember.tap()
        let personName = app.staticTexts["person.name"]
        XCTAssertTrue(personName.waitForExistence(timeout: 5), "Tapping cast should push the person screen")

        // Tap a filmography credit → that title's details (deep graph). The id
        // is kind-qualified so a movie and TV title sharing a TMDB id don't collide.
        let credit = app.buttons["person.credit.movie.550"].firstMatch
        XCTAssertTrue(credit.waitForExistence(timeout: 5), "Person should show their filmography")
        credit.tap()
        XCTAssertTrue(
            app.staticTexts["details.title"].waitForExistence(timeout: 5),
            "Tapping a movie credit should push movie details"
        )
    }

    @MainActor
    func testSwitchingLanguageToArabicFlipsUILive() {
        let app = XCUIApplication()
        app.launchArguments += ["-uitest-stubs", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()

        app.buttons["Continue as guest"].tap()
        // Starts in English.
        XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 5))

        // Profile → Settings → pick Arabic content language.
        app.tabBars.buttons["Profile"].tap()
        app.buttons["Settings"].firstMatch.tap()
        let arabic = app.buttons["settings.language.ar"]
        XCTAssertTrue(arabic.waitForExistence(timeout: 5))
        arabic.tap()

        // The shell rebuilds in Arabic — the tab bar is recreated with Arabic
        // labels, proving the live switch (no relaunch).
        XCTAssertTrue(
            app.tabBars.buttons["الرئيسية"].waitForExistence(timeout: 5),
            "Selecting Arabic should flip the UI language live"
        )
    }

    @MainActor
    func testArabicLocalizationRendersTranslatedStrings() {
        let app = XCUIApplication()
        app.launchArguments += ["-uitest-stubs", "-AppleLanguages", "(ar)", "-AppleLocale", "ar_EG"]
        app.launch()

        // The auth gate's guest button is a FeatureAuth string resolved against
        // that package's String Catalog — proving per-module localization works.
        let guestArabic = app.buttons["المتابعة كضيف"]
        XCTAssertTrue(guestArabic.waitForExistence(timeout: 5), "Guest button should render in Arabic")
        guestArabic.tap()

        // A tab label (app-target catalog) also localizes.
        XCTAssertTrue(
            app.tabBars.buttons["الرئيسية"].waitForExistence(timeout: 5),
            "The Home tab should render in Arabic"
        )
    }

    @MainActor
    func testTVTabBrowseToShowDetails() {
        let app = XCUIApplication()
        app.launchArguments += ["-uitest-stubs", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()

        app.buttons["Continue as guest"].tap()
        app.tabBars.buttons["TV"].tap()

        // A stubbed show card appears and pushes to TV details.
        let show = app.buttons["tv.show.800"].firstMatch
        XCTAssertTrue(show.waitForExistence(timeout: 5), "TV tab should show stubbed carousels")
        show.tap()

        let title = app.staticTexts["tv.details.title"]
        XCTAssertTrue(title.waitForExistence(timeout: 5), "Tapping a show should push TV details")
        XCTAssertEqual(title.label, "UITest Show 800")
    }

    @MainActor
    func testSettingsThemeSelectionAndSignOut() {
        let app = XCUIApplication()
        app.launchArguments += ["-uitest-stubs", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()

        let guestButton = app.buttons["Continue as guest"]
        guestButton.tap()

        // Profile → Settings.
        app.tabBars.buttons["Profile"].tap()
        app.buttons["Settings"].firstMatch.tap()

        // Selecting the Dark theme marks that row selected.
        let dark = app.buttons["settings.theme.dark"]
        XCTAssertTrue(dark.waitForExistence(timeout: 5), "Settings should show theme options")
        dark.tap()
        XCTAssertTrue(dark.isSelected, "Tapping a theme should select it")

        // A guest session gets a "Sign In" row (not "Sign Out"); tapping it
        // tears down the guest session and returns to the auth gate.
        let signIn = app.buttons["settings.signIn"]
        XCTAssertTrue(signIn.waitForExistence(timeout: 5), "A guest should see Sign In in Settings")
        XCTAssertFalse(app.buttons["settings.signOut"].exists, "A guest should not see Sign Out in Settings")
        signIn.tap()
        XCTAssertTrue(guestButton.waitForExistence(timeout: 5), "Sign In should route to the auth gate")
    }

    @MainActor
    func testDiscoverFiltersReturnResults() {
        let app = XCUIApplication()
        app.launchArguments += ["-uitest-stubs", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
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
