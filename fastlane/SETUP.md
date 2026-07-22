# Fastlane setup (Sprint 9.5–9.7)

> **Status: UNVERIFIED scaffolding.** These files were authored without an Apple
> Developer account or signing assets in the dev environment, so the `beta`,
> `release`, and `screenshots` lanes have **not** been run. `lint` and `test`
> are safe anywhere. Validate the rest on a signing-capable machine.

## Install

```sh
bundle install          # installs the pinned fastlane (see ../Gemfile)
bundle exec fastlane --version
```

## Lanes (9.5)

| Lane | What it does | Needs |
|------|--------------|-------|
| `fastlane lint` | SwiftFormat --lint + SwiftLint --strict (the pre-commit gate) | swiftformat, swiftlint |
| `fastlane test` | App unit + UI tests on the `TMDB-Test` scheme (simulator) | Xcode |
| `fastlane beta` | Build **Staging** → TestFlight | signing + ASC key |
| `fastlane release` | Build **Live** → App Store (held before review) | signing + ASC key |
| `fastlane screenshots` | Capture EN + AR App Store screenshots | UI test + helper (below) |

## Secrets (env / CI only — never committed)

```
TMDB_ACCESS_TOKEN     # v4 read token; written into Configs/Secrets.xcconfig by the ensure_secrets helper
MATCH_GIT_URL         # git@github.com:<you>/TMDB-signing.git — the private certs repo
MATCH_PASSWORD        # match encryption passphrase
ASC_KEY_ID            # App Store Connect API key id
ASC_ISSUER_ID         # ASC issuer id
ASC_KEY               # contents of the AuthKey_XXXX.p8
FASTLANE_APPLE_ID     # Apple Developer email
```

## Code signing with match (9.6)

`match` keeps encrypted certs + profiles in a **separate private git repo** (set
`MATCH_GIT_URL`). First-time, from a machine with the signing identity:

```sh
bundle exec fastlane match appstore              # creates/stores the App Store identity
bundle exec fastlane match development           # dev identity for device runs
```

CI consumes them read-only (`readonly: is_ci` in the lanes) via a deploy key on
the signing repo + the `MATCH_PASSWORD` secret. Never commit certificates here.

## Screenshots with snapshot (9.7)

The `screenshots` lane needs two things in the `TMDBUITests` target that aren't
committed yet (the helper is Apple-generated and doesn't pass this repo's strict
lint, so it's generated locally rather than vendored):

1. Generate the helper — adds `SnapshotHelper.swift` to the UI test target:

   ```sh
   bundle exec fastlane snapshot init
   ```

2. Add this screenshot UI test (it reuses the offline `-uitest-stubs` seam and
   the same accessibility identifiers the other UI tests use), then run
   `bundle exec fastlane screenshots`:

   ```swift
   //
   //  ScreenshotUITests.swift
   //  TMDB
   //

   import XCTest

   final class ScreenshotUITests: XCTestCase {
       override func setUpWithError() throws {
           continueAfterFailure = false
       }

       @MainActor
       func testCaptureAppStoreScreenshots() {
           let app = XCUIApplication()
           setupSnapshot(app)
           // -uitest-stubs runs offline; snapshot injects the locale/language.
           app.launchArguments += ["-uitest-stubs"]
           app.launch()

           app.buttons["Continue as guest"].tap()
           XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 10))
           snapshot("01-Home")

           app.tabBars.buttons["Search"].tap()
           let field = app.searchFields.firstMatch
           if field.waitForExistence(timeout: 5) {
               field.tap()
               field.typeText("dune")
               _ = app.buttons["search.movie.700"].firstMatch.waitForExistence(timeout: 5)
           }
           snapshot("02-Search")

           app.buttons["search.movie.700"].firstMatch.tap()
           XCTAssertTrue(app.staticTexts["details.title"].waitForExistence(timeout: 5))
           snapshot("03-Details")

           app.tabBars.buttons["Favorites"].tap()
           snapshot("04-Favorites")
       }
   }
   ```

Output lands in `fastlane/screenshots/<lang>/`. `fastlane deliver` / the
`release` lane can then upload them alongside metadata.

## CI

The GitHub Actions pipeline (`.github/workflows/ci.yml`) already covers
`lint` + `test` + the per-env build matrix. Wiring `beta` into a
tag/release-triggered job is the next step once signing secrets are added to
the repo.
