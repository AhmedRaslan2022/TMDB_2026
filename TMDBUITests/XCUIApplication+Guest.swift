//
//  XCUIApplication+Guest.swift
//  TMDB
//
//  Created by Ahmed Raslan on 02/08/2026.
//

import XCTest

extension XCUIApplication {
    /// Enters the shell through the auth gate's guest path.
    ///
    /// `SplashView` is a top `ZStack` layer over the root, so the auth gate
    /// exists in the accessibility hierarchy underneath it from the first
    /// frame. Waiting for mere existence therefore succeeds while the splash
    /// is still covering the screen, and the tap lands on the splash and is
    /// swallowed — the app stays on the auth gate and the following assertion
    /// fails. Wait for the button to become *hittable* instead.
    func tapContinueAsGuest(
        timeout: TimeInterval = 15,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let guestButton = buttons["Continue as guest"]
        let hittable = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "isHittable == true"),
            object: guestButton
        )
        XCTAssertEqual(
            XCTWaiter().wait(for: [hittable], timeout: timeout),
            .completed,
            "Auth gate should become interactive once the launch splash clears",
            file: file,
            line: line
        )
        guestButton.tap()
    }
}
