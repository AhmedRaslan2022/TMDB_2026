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
- [x] 1.2 SwiftData stack: ModelContainer per env + in-memory container for tests
- [x] 1.3 @Model types: FavoriteMovie, RecentSearch, CachedMovie
- [x] 1.4 AppCoordinator (@Observable): root switch (auth vs main), selected tab
- [x] 1.5 Route enums per feature (Hashable) + navigationDestination wiring in app target
- [x] 1.6 TabBar shell (Home/Search/Favorites/Profile) with placeholder views
- [x] 1.7 Each tab owns its NavigationStack bound to a child coordinator
- [x] 1.8 Sheet/fullScreenCover presentation via coordinator
- [x] 1.9 [test] KeychainManager + AppEnvironment unit tests (Swift Testing)

### Sprint 1 Definition of Done — verified 2026-07-17 ✅
- [x] App launches into auth-gated shell (auth gate → Continue → tab shell; UI test + screenshot)
- [x] Can store/read a value in Keychain — 7 unit tests (macOS host) + in-app iOS roundtrip logged: `keychain roundtrip OK`
- [x] Tab switching + a test push navigation work — UI test covers gate, push to details, back, tab switch, sheet, sign-out
- [x] Tests green — 33 package tests (6 CoreEnvironment, 15 Networking, 12 CoreStorage) + 14 app unit tests + 1 UI test; all 4 schemes build; lint clean

### Sprint 1 Decisions / Deviations
- 1.9: Explicit `deinit {}` in TabCoordinator works around a swift-frontend 6.3 EarlyPerfInliner crash on generic @Observable classes under -O (Staging/Live only). Smoke check extended with an in-app keychain roundtrip.
- 1.8: Modals owned by AppCoordinator (Sheet/FullScreenCover Identifiable enums) and attached once at RootView; demo About sheet + What's New cover from Profile. signOut clears modals too.
- 1.6/1.7 (pair PR): generic `TabCoordinator<Route>` instead of four near-identical classes; classic `.tabItem` API (the `Tab` builder is iOS 18+, min target is 17). Feature views report intent via closures; only coordinators mutate paths.
- Env xcconfigs were moved in Xcode to a root `Enviroments/` folder (rode into the 1.1 commit); project refs and `#include ../Configs/Shared.xcconfig` fixed in 1.4. Secrets/Shared stay in `Configs/`.
- 1.4: Auth gate placeholder view lives in FeatureAuth; AppCoordinator exposes completeAuthGate()/signOut(). Missing `import SwiftData` in TMDBApp (from 1.2) caught and fixed here — earlier build check had a false positive.
- 1.1: `SecureStorage` protocol + `KeychainManager` actor; typed `SecureStorageKey` enum. `removeAll` deletes per key (service-wide SecItemDelete only removes the first match on macOS). Keychain tests run on the macOS host via `swift test` — unhosted iOS-simulator test runners lack the keychain entitlement (errSecMissingEntitlement); in-app iOS keychain roundtrip is verified at the sprint DoD instead.

### Post-Sprint-1 refactors
- 2026-07-17: CoreStorage package split into three products/targets — `KeychainStorage` (SecureStorage + KeychainManager), `SwiftDataStorage` (@Model types + ModelContainerFactory), `UserDefaultsStorage` (new `DefaultsStorage` protocol + `UserDefaultsManager`, first key `hasSeenOnboarding`). Package name/path stays `CoreStorage`; the umbrella `CoreStorage` product is gone. App links Keychain+SwiftData only; features get all three.

## Sprint 2 — Auth Feature

- [x] 2.1 Domain: LoginUseCase, CreateGuestSessionUseCase, LogoutUseCase, repo protocols
- [x] 2.2 Data: auth DTOs + mappers + AuthRemoteDataSource + repository impl
- [x] 2.3 Login flow: request token → ASWebAuthenticationSession approval → create session
- [x] 2.4 Guest session path
- [x] 2.5 Persist session ID + account ID in Keychain; validate on launch
- [ ] 2.6 Logout: remote delete + wipe Keychain + clear user-scoped SwiftData
- [x] 2.7 Presentation: AuthViewModel (@Observable @MainActor) + ViewState enum + views
- [x] 2.8 Wire auth state into AppCoordinator root switch
- [ ] 2.9 [test] AuthViewModel + use cases with mocked repos; URLProtocol-stubbed data source

### Sprint 2 Decisions / Deviations
- 2.5+2.8 review follow-ups (tracked): (a) `AppCoordinator.restoreSession` positive branch + `signOut`→logout are untested — the stub always returns nil; add coordinator tests with a configurable stub session under 2.9. (b) `signOut` fires logout as a detached Task, so very fast sign-out→"Continue as guest" could let logout's `removeAll` wipe the newly-saved guest session (next launch shows the gate) — serialize/await teardown when hardening logout in 2.6.
- 2.5+2.8 (pair PR): `SessionRepositoryImpl` (keychain-backed) encodes session kind by which key holds a value (`.sessionID` = authenticated, `.guestSessionID` = guest; saving one clears the other); `clearSession` = `removeAll`. "Validate on launch" = restore the persisted session (`AppCoordinator.restoreSession`); deeper API-side validation deferred (v3 has no cheap validate endpoint). Wiring: `AppContainer` now composes the auth vertical + owns the `AppCoordinator` (single composition root — no cross-`@State` ref in `TMDBApp`); `AuthModule` bundles the use cases/session repo and keeps auth types out of the coordinator. `AppCoordinator(auth:)` gains `makeAuthViewModel`, `restoreSession`, and `signOut` now runs `LogoutUseCase` (local wipe first, remote delete best-effort, failures logged). `RootView` builds the VM once in `@State` and shows the real `AuthView`; `AuthPlaceholderView` deleted. DEBUG `-uitest-auth-bypass` launch arg swaps in `AuthModule.stub` so the UI test enters the shell offline (no real network); Sprint 1 UI test updated to drive "Continue as guest". DebugSmokeCheck's keychain roundtrip removed — real persistence covers it and it wrote to `.sessionID`, colliding with launch restore. `.stub`-referencing `#Preview`s gated `#if DEBUG` so stub code stays out of release. 8 SessionRepositoryImpl tests added.
- 2.4+2.7 (pair PR): AuthViewModel (@Observable @MainActor) with exhaustive ViewState (idle/loading/loaded/error(LocalizedStringResource)); login (2.3 flow) and guest (2.4) share one private `run` helper. userCancelled + CancellationError → idle (not error); tokenNotApproved → specific message, else generic. Re-entrancy guard drops taps while loading. Session handoff via injected `onAuthenticated` closure — no navigation in the VM (app-target wiring is 2.8). Real `AuthView` (Sign in with TMDB + Continue as guest, loading overlay, error text) added alongside the old `AuthPlaceholderView`, which stays wired in RootView until 2.8 swaps it. Error strings via LocalizedStringResource keys for String Catalog extraction. 10 VM tests incl. gated-mock loading/re-entrancy coverage; satisfies the same-PR test rule (2.9 remains as the DoD checkpoint).
- 2.3: Pure approval logic (`TMDBApprovalFlow`: URL build + redirect parsing, incl. denied/token-mismatch) split from `WebRequestTokenAuthorizer` (@MainActor, wraps ASWebAuthenticationSession via continuation — OS API has no async form). Callback scheme `tmdb-auth://` needs no Info.plist registration (session intercepts it). canceledLogin + TMDB `denied=true` both → AuthError.userCancelled.
- 2.2: DTOs + AuthRemoteDataSource are internal — composition root only sees `AuthRepositoryImpl(apiClient:)`. 401 on createSession → `AuthError.tokenNotApproved` (can't disambiguate TMDB status codes until APIError exposes the error body). `URLProtocolStub` duplicated as public into SharedTestSupport; the NetworkingTests copy can't move there without a Shared→Networking package cycle. Guest expiry dropped in mapping per the 2.1 decision.
- 2.1: Web approval abstracted as `RequestTokenAuthorizer` protocol in Domain (implemented with ASWebAuthenticationSession in 2.3) so LoginUseCase orchestrates the full token → approval → session → persist flow. Logout wipes local state before the remote delete so the device is always logged out even if the network call fails (error still propagates). Guest expiry not modelled — 2.5 validates against the API instead. First Features test target (FeatureAuthTests) added to the manifest.

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
