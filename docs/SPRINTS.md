# TMDB Showcase App — Sprint & Task Breakdown

Solo build, **2-week sprints**. Each sprint has a goal, tasks (with rough estimates in points — 1pt ≈ half a day), and a Definition of Done (DoD). Tasks are written so they map cleanly to GitHub Issues later, and the vertical slices (auth, one feature end-to-end) mirror how real teams sequence work.

**Labels used:** `[core]` foundation/shared, `[feat]` feature work, `[infra]` tooling/CI, `[test]` testing, `[polish]` UX/a11y/i18n.

---

## Sprint 0 — Foundation & Tooling (2 weeks)
**Goal:** Empty app launches on all 4 environments; module skeleton compiles; networking client can hit TMDB.

| # | Task | Pts | Label |
|---|---|---|---|
| 0.1 | Create Xcode workspace + thin app target (composition root only) | 2 | core |
| 0.2 | Scaffold all SPM packages (Core/*, Features/*, Shared) with empty targets + dependency graph wired | 3 | core |
| 0.3 | Add SwiftLint + SwiftFormat, pre-commit hook, `.editorconfig` | 2 | infra |
| 0.4 | Create 4 xcconfig files + 4 build configs + 4 schemes | 3 | infra |
| 0.5 | `Secrets.xcconfig` (git-ignored) + `Secrets.example.xcconfig` committed | 1 | infra |
| 0.6 | `CoreEnvironment.AppEnvironment` — type-safe config reader from Info.plist | 2 | core |
| 0.7 | Per-env bundle IDs, app names, DEV/STG icon badge | 2 | infra |
| 0.8 | `CoreNetworking`: APIClient (async/await), Endpoint protocol, request builder, error mapping | 4 | core |
| 0.9 | Auth interceptor injecting v4 Bearer token; smoke-test `/configuration` call | 2 | core |
| 0.10 | `CoreUI` design tokens: colors, typography, spacing, base components stub | 3 | core |
| 0.11 | DI approach decided + `AppContainer` skeleton | 2 | core |
| 0.12 | README v1: architecture intent, module graph, setup steps | 2 | infra |

**DoD:** All 4 schemes build & run a blank screen; `/configuration` returns 200 in a debug log; lint passes; repo pushed with clean history.

---

## Sprint 1 — Persistence & App Shell (2 weeks)
**Goal:** Keychain + SwiftData stacks working; coordinator-driven tab bar with auth gate and placeholder screens.

| # | Task | Pts | Label |
|---|---|---|---|
| 1.1 | `CoreStorage.KeychainManager` — actor over Security framework, typed API | 3 | core |
| 1.2 | SwiftData stack: `ModelContainer` per env + in-memory container for tests | 3 | core |
| 1.3 | Define `@Model` types: FavoriteMovie, RecentSearch, CachedMovie | 2 | core |
| 1.4 | `AppCoordinator` (@Observable): root switch (auth vs main), selected tab | 3 | core |
| 1.5 | Route enums per feature (Hashable) + `navigationDestination` wiring in app target | 3 | core |
| 1.6 | TabBar shell (Home/Search/Favorites/Profile) with placeholder views | 2 | feat |
| 1.7 | Each tab owns its `NavigationStack` bound to a child coordinator | 3 | core |
| 1.8 | Sheet/fullScreenCover presentation via coordinator | 2 | core |
| 1.9 | `[test]` KeychainManager + AppEnvironment unit tests (Swift Testing) | 2 | test |

**DoD:** App launches into auth-gated shell; can store/read a value in Keychain; tab switching + a test push navigation work; tests green.

---

## Sprint 2 — Auth Feature (2 weeks)
**Goal:** Full TMDB auth vertical slice, clean-architecture layered, session persisted.

| # | Task | Pts | Label |
|---|---|---|---|
| 2.1 | Domain: `LoginUseCase`, `CreateGuestSessionUseCase`, `LogoutUseCase`, repo protocols | 3 | feat |
| 2.2 | Data: auth DTOs + mappers + `AuthRemoteDataSource` + repository impl | 3 | feat |
| 2.3 | Login flow: request token → `ASWebAuthenticationSession` approval → create session | 4 | feat |
| 2.4 | Guest session path | 2 | feat |
| 2.5 | Persist session ID + account ID in Keychain; validate on launch | 2 | feat |
| 2.6 | Logout: remote delete + wipe Keychain + clear user-scoped SwiftData | 2 | feat |
| 2.7 | Presentation: `AuthViewModel` (@Observable @MainActor) + `ViewState` enum + views | 3 | feat |
| 2.8 | Wire auth state into `AppCoordinator` root switch | 2 | core |
| 2.9 | `[test]` AuthViewModel + use cases with mocked repos; URLProtocol-stubbed data source | 3 | test |

**DoD:** User can log in with a TMDB account or as guest, session survives relaunch, logout returns to login; auth tests green; no hardcoded secrets.

---

## Sprint 3 — Home & Movie Details (2 weeks)
**Goal:** The headline vertical slice — concurrent multi-section home + rich details.

| # | Task | Pts | Label |
|---|---|---|---|
| 3.1 | Domain + Data for movie lists (trending/popular/now playing/upcoming/top rated) | 3 | feat |
| 3.2 | `HomeViewModel`: parallel section fetch with `TaskGroup`; per-section `ViewState` | 4 | feat |
| 3.3 | Home UI: horizontal carousels, day/week trending toggle, pull-to-refresh | 3 | feat |
| 3.4 | Pagination (infinite scroll) for section "see all" lists | 3 | feat |
| 3.5 | Skeleton shimmer loading + empty/error states | 2 | polish |
| 3.6 | Async image loader: actor cache (memory + disk) OR integrate Kingfisher | 3 | core |
| 3.7 | Movie Details: domain/data (details, credits, videos, similar, recommendations) | 3 | feat |
| 3.8 | Details UI: stretchy backdrop, rating ring, genres, cast carousel, trailers, similar | 4 | feat |
| 3.9 | Navigate Home → Details via coordinator route | 1 | core |
| 3.10 | `[test]` HomeViewModel (TaskGroup paths), mappers, image cache | 3 | test |

**DoD:** Home loads 5 sections in parallel with graceful per-section failure; details screen fully populated; images cached; navigation via coordinator; tests green.

---

## Sprint 4 — Search & Favorites (2 weeks)
**Goal:** Debounced search + offline-first favorites synced with TMDB.

| # | Task | Pts | Label |
|---|---|---|---|
| 4.1 | Search domain/data (`SearchMoviesUseCase`, Discover-ready) | 2 | feat |
| 4.2 | `SearchViewModel`: `AsyncStream` debounce, cancellation of in-flight tasks | 4 | feat |
| 4.3 | Recent searches CRUD via SwiftData (create/read/delete) | 2 | feat |
| 4.4 | Search UI: results grid, recent list, empty/no-results/error states | 3 | feat |
| 4.5 | Favorites domain/data: SwiftData local source + TMDB remote source | 3 | feat |
| 4.6 | Sync strategy: local favorites ↔ account favorites when authenticated | 3 | feat |
| 4.7 | Favorite toggle with optimistic UI + rollback on failure | 3 | feat |
| 4.8 | Favorites UI: grid, swipe-to-remove, offline support | 2 | feat |
| 4.9 | `[test]` SearchViewModel debounce/cancel, Favorites sync + SwiftData in-memory | 3 | test |

**DoD:** Search-as-you-type debounced & cancellable; recent searches persist; favorites work offline and sync when logged in; optimistic toggle rolls back on error; tests green.

---

## Sprint 5 — Profile, Watchlist, Ratings & Discovery (2 weeks)
**Goal:** Round out account features + writes to the API + advanced discovery.

| # | Task | Pts | Label |
|---|---|---|---|
| 5.1 | Profile domain/data: account details, favorites/watchlist counts | 2 | feat |
| 5.2 | Profile UI: avatar, username, stats, settings entry, env indicator (debug) | 3 | feat |
| 5.3 | Watchlist feature: reuse favorites plumbing for second synced collection | 3 | feat |
| 5.4 | Movie rating: POST rating with optimistic UI (write demo) | 3 | feat |
| 5.5 | Advanced search filters via Discover endpoint (genre, year, rating, sort) | 4 | feat |
| 5.6 | Settings screen: theme toggle, language, cache clear, logout | 2 | feat |
| 5.7 | `[test]` Watchlist/ratings repositories, Discover query building | 3 | test |

**DoD:** Profile shows real account data; watchlist + ratings write to TMDB; advanced filters return correct results; settings functional; tests green.

---

## Sprint 6 — TV Shows & Person Details (2 weeks)
**Goal:** Prove the layers generalize to a second media type + deep navigation graphs.

| # | Task | Pts | Label |
|---|---|---|---|
| 6.1 | Generalize movie domain to reuse for TV (generic media entity or protocol) | 3 | feat |
| 6.2 | TV domain/data: on-air, popular, top-rated, TV details | 3 | feat |
| 6.3 | Home: segmented Movies/TV OR a dedicated TV tab | 3 | feat |
| 6.4 | Person/Actor details: domain/data (bio, filmography, images) | 3 | feat |
| 6.5 | Person UI + navigation from cast carousel → person → their movies (deep graph) | 3 | feat |
| 6.6 | `[test]` reuse-safety tests: same use cases across movie/TV | 2 | test |

**DoD:** TV content browsable through the same architecture; tapping a cast member opens their filmography and navigates onward; no code duplication of core logic; tests green.

---

## Sprint 7 — Platform Integration (2 weeks)
**Goal:** The features that justify the coordinator + show platform depth.

| # | Task | Pts | Label |
|---|---|---|---|
| 7.1 | Deep linking: URL → route stack translation in coordinator (`tmdbapp://movie/123`) | 4 | feat |
| 7.2 | Universal Links: associated domains + apple-app-site-association handling | 3 | feat |
| 7.3 | App Group + shared SwiftData for widget/app data sharing | 2 | core |
| 7.4 | WidgetKit "Trending today" widget (small/medium) | 4 | feat |
| 7.5 | App Intents / Siri Shortcuts ("Show my watchlist") | 3 | feat |
| 7.6 | Live Activity / Dynamic Island: "releasing today" countdown | 4 | feat |
| 7.7 | `[test]` deep-link parser unit tests (URL → route) | 2 | test |

**DoD:** A cold-start deep link lands on the right screen with a correct back stack; widget shows live data; Siri shortcut works; one Live Activity demoable; tests green.

---

## Sprint 8 — Localization, Theming & Accessibility (2 weeks)
**Goal:** Polish that reviewers in your market notice — full AR/EN + a11y.

| # | Task | Pts | Label |
|---|---|---|---|
| 8.1 | Extract all strings to String Catalogs (`.xcstrings`) | 3 | polish |
| 8.2 | Arabic localization + full RTL layout audit (mirroring, alignment) | 4 | polish |
| 8.3 | Request TMDB content in device language (`language`/`region` params) | 2 | feat |
| 8.4 | Dark/Light theme finalization + alternate app icons | 3 | polish |
| 8.5 | Accessibility: VoiceOver labels, traits, Dynamic Type across all screens | 4 | polish |
| 8.6 | `[test]` snapshot tests for CoreUI components (light/dark, LTR/RTL, type sizes) | 4 | test |

**DoD:** App fully usable in Arabic with correct RTL; VoiceOver reads every meaningful element; Dynamic Type doesn't break layouts; snapshot suite green.

---

## Sprint 9 — Quality Hardening & CI/CD (2 weeks)
**Goal:** Green pipeline, automated releases, portfolio-ready repo.

| # | Task | Pts | Label |
|---|---|---|---|
| 9.1 | Fill test coverage gaps: target ~80% on Domain + ViewModels | 4 | test |
| 9.2 | UI tests for critical paths (login, add favorite) against Test scheme | 3 | test |
| 9.3 | GitHub Actions: build + test + lint on every PR | 3 | infra |
| 9.4 | GitHub Actions: per-env build matrix | 2 | infra |
| 9.5 | Fastlane lanes: `lint`, `test`, `beta` (TestFlight/Staging), `release` (Live) | 4 | infra |
| 9.6 | Fastlane `match` for code signing; secrets injected from CI, not repo | 3 | infra |
| 9.7 | Fastlane `snapshot` for automated App Store screenshots (AR + EN) | 3 | infra |
| 9.8 | README final: diagram, module graph, GIFs, decisions log, setup | 3 | infra |

**DoD:** PRs blocked unless build+test+lint pass; `fastlane beta` ships to TestFlight; signing automated; README tells the architecture story with visuals.

---

## Sprint 10 — App Launch Experience & Onboarding
**Goal:** A polished, correct first-run and cold-start experience — static launch screen → in-app splash → the right destination (onboarding, auth, or the shell) based on onboarding + authorization status — plus first-launch-only interactive onboarding, and UIKit lifecycle seams.

| # | Task | Pts | Label |
|---|---|---|---|
| 10.1 | App + Scene delegate lifecycle seams via `@UIApplicationDelegateAdaptor` (SwiftUI App lifecycle retained). Documented hooks for launch + scene lifecycle; deep links keep using `.onOpenURL` | 2 | feat |
| 10.2 | Static launch screen (Info.plist `UILaunchScreen`) whose background/logo matches the in-app splash for a seamless hand-off | 1 | feat |
| 10.3 | `FeatureOnboarding` package: interactive, paged onboarding shown on **first launch only**; `OnboardingViewModel` + an `OnboardingCompletion` port the app fulfills (persists the flag) | 3 | feat |
| 10.4 | Splash as the root + `LaunchUseCase` (onboarding-complete + auth-session status → `LaunchDestination` of onboarding / auth / main); `AppCoordinator.RootScene` gains `.splash` + `.onboarding`; splash runs the use case then routes | 3 | feat |

**DoD:** cold start shows the static launch screen → splash while the launch decision runs, then lands on onboarding (first launch), the auth gate (no session), or the shell (session restored) with no auth-gate flash; onboarding shows once and never again; `LaunchUseCase` + `OnboardingViewModel` unit-tested; delegates in place; lint + full suite green.

---

## Sprint 11 — Manual QA & Bug Bash (ongoing)
**Goal:** Drive every feature by hand on device + simulator, catalog defects in `docs/BUGS.md`, and fix them one-by-one — each fix carrying a regression test so the same bug can't return.

This sprint is **demand-driven**: it has no fixed task count. The backlog is the running bug log in `docs/BUGS.md`, which the product owner (Ahmed) fills as issues are found during hands-on testing. Each open bug becomes a task.

| # | Task | Pts | Label |
|---|---|---|---|
| 11.1 | Manual QA pass: work the per-feature checklist (Auth, Home, Details, Search, Favorites, Profile, TV, Person, Settings/i18n/theme/icons, launch/onboarding) on device + simulator; log every defect in `docs/BUGS.md` | 3 | qa |
| 11.2 | Bug-fix loop: for each open bug, branch `sprint-11/bug-<id>-<slug>`, reproduce, fix, add a regression test that fails before / passes after, then squash-merge | — | fix |
| 11.3 | Triage & severity: keep `docs/BUGS.md` current — severity (S1 blocker … S4 polish), status (Open / In progress / Fixed / Won't fix), and the closing commit for each | 1 | qa |

**Bug workflow (per entry in `docs/BUGS.md`):**
1. Ahmed adds a row: ID, area, steps to reproduce, expected vs actual, severity.
2. Claude reproduces, opens `sprint-11/bug-<id>-<slug>`, writes a **failing** regression test that captures the defect.
3. Fix until the test (and the full suite + lint) is green; update the row to Fixed with the commit hash.
4. Squash-merge to `develop`; the bug stays in the log as a closed record.

**DoD:** `docs/BUGS.md` has zero **S1/S2** (blocker/major) bugs in `Open`/`In progress`; every fixed bug has a named regression test; the manual-QA checklist is fully walked at least once on a real device.

---

## Summary

| Sprint | Theme | ~Pts |
|---|---|---|
| 0 | Foundation & tooling | 28 |
| 1 | Persistence & shell | 23 |
| 2 | Auth feature | 24 |
| 3 | Home & details | 29 |
| 4 | Search & favorites | 25 |
| 5 | Profile, watchlist, ratings, discovery | 20 |
| 6 | TV shows & person | 17 |
| 7 | Platform integration | 22 |
| 8 | i18n, theming, a11y | 20 |
| 9 | Quality & CI/CD | 25 |
| 10 | App launch experience & onboarding | 9 |
| 11 | Manual QA & bug bash | ongoing |

**~10 sprints / ~20 weeks** at a sustainable solo pace. If you want to ship a demoable version sooner, Sprints 0–4 alone (through favorites) already showcase every architectural requirement you listed — the rest is breadth and polish.

**Workflow tip:** one feature branch per task, PR into `develop`, conventional commits, and squash-merge. Even solo, this produces the exact GitHub history that makes a portfolio repo credible — and it's what Sprint 9's CI hooks into.
