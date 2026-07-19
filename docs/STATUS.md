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
- [x] 2.6 Logout: remote delete + wipe Keychain + clear user-scoped SwiftData
- [x] 2.7 Presentation: AuthViewModel (@Observable @MainActor) + ViewState enum + views
- [x] 2.8 Wire auth state into AppCoordinator root switch
- [x] 2.9 [test] AuthViewModel + use cases with mocked repos; URLProtocol-stubbed data source

### Sprint 2 Definition of Done — verified 2026-07-18 ✅
- [x] Log in as guest — full vertical works offline-stubbed (UI test) and live path is wired; TMDB-account login implemented + reviewed end-to-end (token → ASWebAuthenticationSession → session → keychain). ⚠️ Manual once-over with a real TMDB account still recommended (web approval can't run in automated tests).
- [x] Session survives relaunch — keychain persistence + `restoreSession` (positive/negative coordinator tests); manual relaunch check recommended alongside the account login pass.
- [x] Logout returns to login — UI test (sign out → gate) + coordinator test (signOut runs full teardown).
- [x] Auth tests green — 97 package tests (6 CoreEnvironment, 15 Networking, 19 CoreStorage, 57 FeatureAuth incl. mocked-repo use cases, AuthViewModel, URLProtocol-stubbed data source per the 2.9 list) + app unit tests (incl. 4 new auth-flow coordination tests, SwiftDataUserStore) + 1 UI test; all 4 schemes build; lint clean.
- [x] No hardcoded secrets — verified per-PR by the code-reviewer agent; token only in git-ignored Secrets.xcconfig.

### Sprint 2 Decisions / Deviations
- 2.9: Named 2.9 coverage had landed with each task (same-PR rule); this task closed both tracked follow-ups: (a) coordinator tests for restore/signOut added (TMDBTests/AuthFlowCoordinationTests, configurable stub session repo); (b) sign-out race FIXED — new `AuthTeardownBarrier` in AuthModule: signOut registers the logout Task, and the VM's login/guest use cases are wrapped in teardown-awaiting decorators, so a new session always waits for the wipe (ordering-asserted test with a gated logout mock). `AuthModule.logOut` replaced by `beginLogout(onError:)`.
- 2.6: LogoutUseCase now wipes user-scoped SwiftData too, via a new Domain `UserScopedDataStore` protocol (keeps the use case ignorant of concrete @Model types) implemented by app-target `SwiftDataUserStore` over the ModelContainer. Teardown order: keychain clear → SwiftData clear → remote delete (local-first; a user-data failure propagates and skips remote). Clears FavoriteMovie + RecentSearch; leaves CachedMovie (non-user content cache, refreshed on next fetch). Tests: LogoutUseCase gains user-data assertions + failure path (6 cases); new SwiftDataUserStoreTests (app target, in-memory container) verifies favorites/searches deleted and cache kept. Sign-out race from the 2.5+2.8 follow-up (b) is NOT yet resolved — signOut still fire-and-forgets logout; deferred to a small follow-up (needs re-arming the gate after local teardown, or resetting the reused AuthViewModel to .idle on return). Still tracked below.
- 2.5+2.8 review follow-ups (tracked): (a) `AppCoordinator.restoreSession` positive branch + `signOut`→logout are untested — the stub always returns nil; add coordinator tests with a configurable stub session under 2.9. (b) `signOut` fires logout as a detached Task, so very fast sign-out→"Continue as guest" could let logout's `removeAll` wipe the newly-saved guest session (next launch shows the gate) — serialize/await teardown when hardening logout in 2.6.
- 2.5+2.8 (pair PR): `SessionRepositoryImpl` (keychain-backed) encodes session kind by which key holds a value (`.sessionID` = authenticated, `.guestSessionID` = guest; saving one clears the other); `clearSession` = `removeAll`. "Validate on launch" = restore the persisted session (`AppCoordinator.restoreSession`); deeper API-side validation deferred (v3 has no cheap validate endpoint). Wiring: `AppContainer` now composes the auth vertical + owns the `AppCoordinator` (single composition root — no cross-`@State` ref in `TMDBApp`); `AuthModule` bundles the use cases/session repo and keeps auth types out of the coordinator. `AppCoordinator(auth:)` gains `makeAuthViewModel`, `restoreSession`, and `signOut` now runs `LogoutUseCase` (local wipe first, remote delete best-effort, failures logged). `RootView` builds the VM once in `@State` and shows the real `AuthView`; `AuthPlaceholderView` deleted. DEBUG `-uitest-auth-bypass` launch arg swaps in `AuthModule.stub` so the UI test enters the shell offline (no real network); Sprint 1 UI test updated to drive "Continue as guest". DebugSmokeCheck's keychain roundtrip removed — real persistence covers it and it wrote to `.sessionID`, colliding with launch restore. `.stub`-referencing `#Preview`s gated `#if DEBUG` so stub code stays out of release. 8 SessionRepositoryImpl tests added.
- 2.4+2.7 (pair PR): AuthViewModel (@Observable @MainActor) with exhaustive ViewState (idle/loading/loaded/error(LocalizedStringResource)); login (2.3 flow) and guest (2.4) share one private `run` helper. userCancelled + CancellationError → idle (not error); tokenNotApproved → specific message, else generic. Re-entrancy guard drops taps while loading. Session handoff via injected `onAuthenticated` closure — no navigation in the VM (app-target wiring is 2.8). Real `AuthView` (Sign in with TMDB + Continue as guest, loading overlay, error text) added alongside the old `AuthPlaceholderView`, which stays wired in RootView until 2.8 swaps it. Error strings via LocalizedStringResource keys for String Catalog extraction. 10 VM tests incl. gated-mock loading/re-entrancy coverage; satisfies the same-PR test rule (2.9 remains as the DoD checkpoint).
- 2.3: Pure approval logic (`TMDBApprovalFlow`: URL build + redirect parsing, incl. denied/token-mismatch) split from `WebRequestTokenAuthorizer` (@MainActor, wraps ASWebAuthenticationSession via continuation — OS API has no async form). Callback scheme `tmdb-auth://` needs no Info.plist registration (session intercepts it). canceledLogin + TMDB `denied=true` both → AuthError.userCancelled.
- 2.2: DTOs + AuthRemoteDataSource are internal — composition root only sees `AuthRepositoryImpl(apiClient:)`. 401 on createSession → `AuthError.tokenNotApproved` (can't disambiguate TMDB status codes until APIError exposes the error body). `URLProtocolStub` duplicated as public into SharedTestSupport; the NetworkingTests copy can't move there without a Shared→Networking package cycle. Guest expiry dropped in mapping per the 2.1 decision.
- 2.1: Web approval abstracted as `RequestTokenAuthorizer` protocol in Domain (implemented with ASWebAuthenticationSession in 2.3) so LoginUseCase orchestrates the full token → approval → session → persist flow. Logout wipes local state before the remote delete so the device is always logged out even if the network call fails (error still propagates). Guest expiry not modelled — 2.5 validates against the API instead. First Features test target (FeatureAuthTests) added to the manifest.

## Sprint 3 — Home & Movie Details

- [x] 3.1 Domain + Data for movie lists (trending/popular/now playing/upcoming/top rated)
- [x] 3.2 HomeViewModel: parallel section fetch with TaskGroup; per-section ViewState
- [x] 3.3 Home UI: horizontal carousels, day/week trending toggle, pull-to-refresh
- [x] 3.4 Pagination (infinite scroll) for section "see all" lists
- [x] 3.5 Skeleton shimmer loading + empty/error states
- [x] 3.6 Async image loader: actor cache (memory + disk)
- [x] 3.7 Movie Details: domain/data (details, credits, videos, similar, recommendations)
- [x] 3.8 Details UI: stretchy backdrop, rating ring, genres, cast carousel, trailers, similar
- [x] 3.9 Navigate Home → Details via coordinator route
- [ ] 3.10 [test] HomeViewModel (TaskGroup paths), mappers, image cache

### Sprint 3 Decisions / Deviations
- 3.8+3.9 (pair PR): `MovieDetailsViewModel` (exhaustive ViewState; idempotent load; URL helpers for backdrop w780 with poster fallback, profile w185, poster w342, YouTube/Vimeo watch links + YouTube thumbnails; `featuredVideos` = official trailers first, teasers only as fallback). UI decomposed: `DetailsHeaderView` (GeometryReader stretch-on-pull backdrop against a named scroll space; title/tagline/year·runtime·genres meta via localized Duration formatting), `RatingRing`, `CastSection` (top-15 billing, circular headshots), `VideosSection` (external `Link` — external URLs aren't coordinator navigation), `RelatedSection` ×2 (similar/recommended). Prerequisite refactor: `MoviePosterCard` promoted to CoreUI as model-agnostic `PosterCard`(+skeleton) per the no-duplication rule; FeatureHome swapped to it. 3.9: `RouteDestinations` now maps `.movieDetails` on all three tabs to the real screen (per-tab push closures for related-movie taps), `makeMovieDetailsViewModel` factory threaded through, `MovieDetailsPlaceholderView` deleted, UI test asserts the real details title (`details.title` == "UITest Movie 550") via a new offline details stub. 8 VM tests.
- 3.7: One request, not five — `/movie/{id}?append_to_response=credits,videos,similar,recommendations` returns a `MovieDetailsBundle` (details + cast + videos + similar + recommendations) via one `FetchMovieDetailsUseCase`. Entities feature-local (`MovieDetails`/`Genre`/`CastMember` with credit+person IDs/`MovieVideo` with typed `Site`); similar/recommendations map to shared `Movie`. Mapping: lenient (missing appended sections → empty; empty tagline/zero runtime → nil), cast sorted by billing order, unknown video sites dropped. DTO twins of FeatureHome's movie DTO + date parser are deliberate — Data layers stay feature-local, never shared. 6 tests through the stubbed client incl. bare payload, ordering, site filtering, 404. Presentation stays a placeholder until 3.8.
- 3.6: `ImageCache` actor in CoreUI (per CLAUDE.md, no Kingfisher): memory (NSCache, 64MB cost cap) → disk (Caches/ImageCache, SHA-256 filenames, best-effort writes) → URLSession, with in-flight Task coalescing (N views, 1 request; a cancelled awaiter doesn't kill the shared load — detached task). Stores raw bytes; decode per platform in `RemoteImage` (AsyncImage-shaped API: content+placeholder closures, URL-change reset without re-appearance flash). Injection via SwiftUI `@Entry` environment key with an overridable default — recorded as the DI mechanism (environment-scoped, not a singleton; composition root/tests can replace). MoviePosterCard swapped off AsyncImage, layout untouched. New CoreUITests target (closes the 3.4 deferred note): 7 cache tests (layers, coalescing via requestCount added to URLProtocolStub, failure-not-cached, clears) + 3 TMDBImageURL contract tests. Failures never cached; UI-test stub movies still poster-less so nothing hits the network there. Review caught two real bugs pre-merge: (a) `@Entry`'s default expression is re-evaluated per read — the default now aliases a stable file-private instance AND the composition root injects `container.imageCache` explicitly (the env-key DI decision, actually wired); (b) a load surviving awaiter cancellation could write the OLD url's image over a reused cell's new url — guarded with `Task.isCancelled` after the await. Tests hardened: memory-hit test now deletes the disk layer first (was passing via disk); class suite + deinit cleanup; clearDisk tolerates a clean cache.
- 3.5: CoreUI gains `.shimmering()` (gradient-mask sweep; Reduce Motion → opacity pulse instead) + `SkeletonBox`. FeatureHome: `MoviePosterCardSkeleton` mirrors the card footprint; carousel loading rows and the see-all loading grid are shimmering skeletons, `.accessibilityHidden` so VoiceOver skips placeholder noise. Section empty/error rows get icons; see-all empty uses `ContentUnavailableView`, error keeps the custom Retry view. No VM changes — purely presentational, no new tests (92 package tests still green).
- 3.4: `HomeRoute.seeAll(section:window:)` (window captured at push time — toggling on Home doesn't mutate a pushed list) → `MovieListView` grid over `MovieListViewModel`: single exhaustive ViewState where load-more mutates `loaded`'s Content in place (movies/hasMorePages/isLoadingMore) so the list never vanishes mid-scroll. Trigger = item within last 5 (`loadMoreIfNeeded(after:)` from cell `.task`); results deduped by ID (TMDB repeats items across pages — ForEach crash guard); failed next page keeps content, stops the spinner and re-arms. Poster URL builder promoted to CoreUI (`TMDBImageURL`, doc'd public API) — shared by both VMs, ready for 3.6. `RouteDestinations.attach` now takes the coordinator + VM factories (destinations with deps get them injected, not located); MainTabView wraps it once. Review-driven: gated-mock test proving the in-flight double-fetch guard (was correct but untestable); dedupe extended to within-page duplicates on both paths. 10 pagination VM tests. Deferred note: CoreUI has no test target yet — `TMDBImageURL`'s contract rides on FeatureHome tests; add CoreUITests when 3.6 grows CoreUI.
- 3.3: HomeView = LazyVStack of `HomeSectionView`s (header + state-driven body: carousel / spinner / error+Retry / empty) over `MoviePosterCard`s; `.refreshable` pull-to-refresh; segmented day/week Picker on trending (closure-backed Binding — no logic in views). Poster images use AsyncImage as a stopgap until 3.6's actor cache (swap is card-internal); URL built by the VM (`posterURL(for:)`, w342) from environment `imageBaseURL` injected via init. Plain spinner + basic error/empty rows for now — 3.5 replaces with shimmer/polish. Wiring: RootView now takes the AppContainer and owns screen VMs in @State; `makeHomeViewModel()` factory on the container. UI-test seam generalized: `-uitest-auth-bypass` renamed `-uitest-stubs`, now also stubbing FetchMovieListUseCase (deterministic offline movies, IDs 550…559, no poster paths so AsyncImage never touches network); UI test drives a stubbed poster card (`home.movie.550`) instead of the deleted placeholder push button. Review-driven fix: `load()` now fetches only `.idle` sections, so the `.task` re-fire on every re-appearance (pop back from details, tab switch) no longer collapses Home to spinners and re-issues 5 requests — resolved sections stay put (freshness = `refresh()`, failures = `retry`). Poster cards combine into one VoiceOver element with a localized "Rated X out of 10" label. 14 VM tests across two suites (SwiftLint type-length forced a split: sequential + concurrency, shared mock in Mocks/HomeMocks.swift).
- 3.2: `HomeSection` enum (display order, maps to `MovieList` given the trending window) + `HomeViewModel` with `[HomeSection: SectionState]` — per-section exhaustive state (idle/loading/loaded/error(LocalizedStringResource)). `withTaskGroup` fans out over sections; states update as each child finishes, so fast sections render before slow ones. `refresh()` keeps stale content until fresh data lands (no skeleton flash); `retry(section:)` for 3.5's error UI; `selectTrendingWindow` re-fetches trending only. CancellationError → back to idle, never error; failed sections drop stale content by design (retry re-fetches). Review-driven hardening: explicit `inFlight` set guards ALL fetches (incl. refresh — refreshing an in-flight section is a no-op) + per-section generation tokens so a window toggle preempts an in-flight trending fetch and its stale result is dropped on arrival (was a desync bug). 11 VM tests incl. gated-mock proofs of parallel independence, toggle-supersedes-fetch, and refresh-skips-in-flight — part of 3.10's named coverage, landed same-PR. Sprint 8 note: LocalizedStringResource defaults to .main bundle; FeatureHome + FeatureAuth error strings need `bundle:` pointing at Bundle.module when the String Catalogs land.
- 3.1: Shared movie entities (`Movie`, `MoviePage` with `hasMorePages`, `TrendingWindow`) live in CoreModels — Home/Details/Search/Favorites all consume them and features can't import each other. One parameterized `FetchMovieListUseCase(list:page:)` over a `MovieList` enum instead of five clone use cases (deviation from the backlog's naming; 3.2's TaskGroup fans out over the enum). Mapper is lenient: missing/unparseable release_date → nil, absent optionals get zero-values — TMDB list items routinely ship partial data. Repository is network-only; offline caching is a later sprint's task. FeatureHomeTests target added; repository+data source tested together through URLProtocol-stubbed URLSessionAPIClient.

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
