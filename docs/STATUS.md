# Project Status

Task checklist mirroring `docs/SPRINTS.md`. One line per deviation/decision.

> **Note:** `docs/PLAN.md` does not exist in this repo — `TMDB-App-Plan.md` was deleted before Sprint 0 started. Architecture rules in `CLAUDE.md` serve as the plan of record until a PLAN.md is added.

## Sprint 0 — Foundation & Tooling

- [x] 0.1 Create Xcode workspace + thin app target
- [x] 0.2 Scaffold all SPM packages with dependency graph wired
- [x] 0.3 SwiftLint + SwiftFormat, pre-commit hook, .editorconfig
- [x] 0.4 Create 4 xcconfig files + 4 build configs + 4 schemes
- [x] 0.5 Secrets.xcconfig (git-ignored) + Secrets.example.xcconfig committed
- [x] 0.6 CoreEnvironment.AppEnvironment — type-safe config reader
- [x] 0.7 Per-env bundle IDs, app names, DEV/STG icon badge
- [x] 0.8 CoreNetworking: APIClient, Endpoint protocol, request builder, error mapping
- [x] 0.9 Auth interceptor (v4 Bearer) + `/configuration` smoke test — 200 OK verified on simulator with the real token
- [x] 0.10 CoreUI design tokens + base components stub
- [x] 0.11 DI approach decided + AppContainer skeleton
- [x] 0.12 README v1

### Sprint 0 Definition of Done — verified 2026-07-15 ✅
- [x] All 4 schemes build & run a blank screen (TMDB-Dev/Staging/Test/Live, iPhone 17 Pro sim)
- [x] `/configuration` returns 200 in a debug log — `SmokeCheck: /configuration → 200 OK (env: Dev)`
- [x] Lint passes — `swiftformat --lint` + `swiftlint --strict` clean; pre-commit hook enforcing
- [x] Repo history clean — one conventional squash commit per task on `develop` ("pushed" pending: no remote configured yet)
- Tests: 21 Swift Testing cases green in Packages/Core (CoreEnvironment, CoreNetworking); app unit test target green on TMDB-Test scheme.

### Decisions / Deviations
- 0.2: Three manifests (Core, Features, Shared) with multiple library products each, matching the CLAUDE.md module map — not 13 separate packages. Swift tools 6.0 (strict concurrency), platform iOS 17.
- 0.3: Pre-commit hook is versioned in `.githooks/`; enable per clone with `git config core.hooksPath .githooks`. Trailing commas mandatory (SwiftFormat + SwiftLint agree).
- 0.4: Debug/Release replaced outright by Dev/Staging/Test/Live (not added alongside). Deployment target lowered from template 26.4 to iOS 17.0. Known SwiftPM heuristic: custom config names build package deps with release-style codegen — accepted.
- 0.6: Throwing `AppEnvironment(infoDictionary:)` for testability + trapping `load(from:)` for the composition root. Partial `TMDB/Info.plist` merged via GENERATE_INFOPLIST_FILE; Info.plist excluded from the synchronized group to avoid duplicate-output collision.
- 0.7: Placeholder script-generated icons (TMDB wordmark + DEV/STG/TEST banner); real branding replaces them in Sprint 8. Test env also badged, not just DEV/STG.
- 0.8: URLProtocol stub lives in CoreNetworkingTests, not SharedTestSupport — Shared already depends on Core, the reverse edge would cycle. Packages declare macOS 14 so `swift test` runs on the host.
- 0.9: BearerAuthInterceptor takes a token-provider closure so CoreNetworking stays independent of CoreEnvironment; composition root bridges them. Debug-only smoke check in the app target.
- 0.11: DI = protocol-based constructor injection composed in `AppContainer` (@MainActor, app target). No service locator, no DI framework, no singletons. Coordinators receive feature dependencies from the container starting Sprint 1.
- Post-sprint refactor (2026-07-17): the single Core package split into six standalone packages under `Packages/Core/*`, and `CoreNetworking` renamed to `Networking` (module, product, package). Features/Shared manifests and app wiring updated; CLAUDE.md module map updated to match.
- Sprint backlog file moved from repo root (`TMDB-App-Sprints.md`) to `docs/SPRINTS.md` per CLAUDE.md.
- No git remote configured yet → per-task branches are squash-merged into `develop` locally; PRs start once a remote exists.

## Sprint 1 — Persistence & App Shell

- [x] 1.1 CoreStorage.KeychainManager — actor over Security framework, typed API
- [ ] 1.2 SwiftData stack: ModelContainer per env + in-memory container for tests
- [ ] 1.3 @Model types: FavoriteMovie, RecentSearch, CachedMovie
- [x] 1.4 AppCoordinator (@Observable): root switch (auth vs main), selected tab
- [x] 1.5 Route enums per feature (Hashable) + navigationDestination wiring in app target
- [ ] 1.6 TabBar shell (Home/Search/Favorites/Profile) with placeholder views
- [ ] 1.7 Each tab owns its NavigationStack bound to a child coordinator
- [ ] 1.8 Sheet/fullScreenCover presentation via coordinator
- [ ] 1.9 [test] KeychainManager + AppEnvironment unit tests (Swift Testing)

### Sprint 1 Decisions / Deviations
- Env xcconfigs were moved in Xcode to a root `Enviroments/` folder (rode into the 1.1 commit); project refs and `#include ../Configs/Shared.xcconfig` fixed in 1.4. Secrets/Shared stay in `Configs/`.
- 1.4: Auth gate placeholder view lives in FeatureAuth; AppCoordinator exposes completeAuthGate()/signOut(). Missing `import SwiftData` in TMDBApp (from 1.2) caught and fixed here — earlier build check had a false positive.
- 1.1: `SecureStorage` protocol + `KeychainManager` actor; typed `SecureStorageKey` enum. `removeAll` deletes per key (service-wide SecItemDelete only removes the first match on macOS). Keychain tests run on the macOS host via `swift test` — unhosted iOS-simulator test runners lack the keychain entitlement (errSecMissingEntitlement); in-app iOS keychain roundtrip is verified at the sprint DoD instead.

## Sprint 2 — Auth Feature
- [ ] 2.1 – 2.9 (not started)

## Sprint 3 — Home & Movie Details
- [ ] 3.1 – 3.10 (not started)

## Sprint 4 — Search & Favorites
- [ ] 4.1 – 4.9 (not started)

## Sprint 5 — Profile, Watchlist, Ratings & Discovery
- [ ] 5.1 – 5.7 (not started)

## Sprint 6 — TV Shows & Person Details
- [ ] 6.1 – 6.6 (not started)

## Sprint 7 — Platform Integration
- [ ] 7.1 – 7.7 (not started)

## Sprint 8 — Localization, Theming & Accessibility
- [ ] 8.1 – 8.6 (not started)

## Sprint 9 — Quality Hardening & CI/CD
- [ ] 9.1 – 9.8 (not started)
