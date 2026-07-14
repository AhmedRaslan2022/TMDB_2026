# TMDB Showcase App — Full Project Plan

A portfolio-grade iOS app built on the TMDB API, designed to demonstrate senior-level iOS skills: modern concurrency, the Observation framework, Clean Architecture + MVVM with Coordinators, SPM modularization, a proper persistence layer, multi-environment configuration, and (later) CI/CD with Fastlane.

---

## 1. Tech Stack & Ground Rules

| Area | Choice |
|---|---|
| Language | Swift 5.10+ (Swift 6 strict concurrency mode as a stretch goal) |
| UI | SwiftUI only |
| State | Observation framework (`@Observable`, `@Bindable`) — **no** `ObservableObject`/`@Published` |
| Concurrency | async/await, `Task`, `TaskGroup`, `AsyncSequence`, actors — **no** Combine, no completion handlers |
| Architecture | Clean Architecture (Domain / Data / Presentation) + MVVM + Coordinator |
| Navigation | SwiftUI `NavigationStack` + `navigationDestination` driven by coordinators |
| Modularization | Local Swift Packages (SPM) |
| Persistence | SwiftData (app data CRUD) + Keychain (sensitive data) |
| Networking | `URLSession` + async/await, custom lightweight client (no Alamofire — shows raw skill) |
| Images | Custom async image loader with actor-based in-memory + disk cache (or Kingfisher if you prefer speed) |
| DI | Lightweight protocol-based DI container (or factory pattern per module) |
| Min iOS | 17.0 (required for `@Observable` + SwiftData) |

---

## 2. Modularization — SPM Package Map

One workspace: a thin **App target** + local packages. Every feature is its own package; every layer is its own target.

```
TMDBApp (Xcode project — app target, only composition root + coordinators wiring)
│
├── Packages/
│   ├── Core/
│   │   ├── CoreNetworking      // API client, endpoints, interceptors, error mapping
│   │   ├── CoreStorage         // SwiftData stack, KeychainManager
│   │   ├── CoreModels          // Shared domain entities (Movie, Genre, User…)
│   │   ├── CoreUI              // Design system: colors, typography, reusable views
│   │   ├── CoreUtilities       // Extensions, logger, date/number formatters
│   │   └── CoreEnvironment     // AppEnvironment, config reader (from xcconfig/Info.plist)
│   │
│   ├── Features/
│   │   ├── FeatureAuth         // Login (TMDB auth flow), guest mode, session mgmt
│   │   ├── FeatureHome         // Trending, Popular, Now Playing, Upcoming sections
│   │   ├── FeatureMovieDetails // Details, cast, videos, similar movies
│   │   ├── FeatureSearch       // Debounced search with AsyncSequence
│   │   ├── FeatureFavorites    // Local (SwiftData) + synced TMDB favorites
│   │   └── FeatureProfile      // Account info, settings, logout, theme
│   │
│   └── Shared/
│       └── SharedTestSupport   // Mocks, stubs, test helpers used by all test targets
```

**Dependency rule (strict, one direction):**
`Features → Core` only. Features never import each other — cross-feature navigation goes through the coordinator layer in the app target. This is the thing reviewers look for.

---

## 3. Clean Architecture Layers (inside every feature package)

```
FeatureHome/
├── Domain/
│   ├── Entities/          // Pure Swift structs (no Codable, no SwiftData)
│   ├── UseCases/          // e.g. FetchTrendingMoviesUseCase (protocol + impl)
│   └── Repositories/      // Repository *protocols* only
├── Data/
│   ├── DTOs/              // Codable API models + mappers → Domain entities
│   ├── DataSources/       // RemoteDataSource (API), LocalDataSource (SwiftData)
│   └── Repositories/      // Repository implementations
└── Presentation/
    ├── ViewModels/        // @Observable @MainActor classes
    ├── Views/             // SwiftUI views
    └── Navigation/        // Feature route enum (Hashable) exposed to coordinator
```

Key demonstrations:
- **Domain is dependency-free** — pure Swift, fully unit-testable.
- DTO ↔ Entity mapping shows you understand boundary separation.
- Use cases injected via protocols → trivial to mock in tests.
- ViewModels expose state as a single `enum ViewState { idle, loading, loaded([Movie]), error(AppError) }` — clean, exhaustive UI rendering.

---

## 4. MVVM + Coordinator with SwiftUI Navigation

- Each tab owns its own `NavigationStack` bound to a coordinator's `NavigationPath` (or a typed `[Route]` array — typed is more impressive).
- `@Observable final class AppCoordinator` holds: selected tab, auth state, and child coordinators (`HomeCoordinator`, `FavoritesCoordinator`, …).
- Feature packages expose a `Route` enum; the app target maps routes → views via `navigationDestination(for:)`. Features stay decoupled.
- Sheets/full-screen covers are also coordinator-driven (`presentedSheet: Route?`).
- **Deep linking ready:** coordinator can translate a URL (`tmdbapp://movie/123`) into a route stack — great demo of the pattern's payoff.

Auth gate: `AppCoordinator` switches root between `AuthFlow` and `MainTabFlow` based on session state read from Keychain at launch.

---

## 5. Persistence Layer

### Keychain (`CoreStorage.KeychainManager`)
Actor-based wrapper over Security framework. Stores:
- TMDB **session ID** / v4 access token
- Account ID
- API key (injected per-environment, never hardcoded in source)

### SwiftData
Full CRUD demonstrations:
- `FavoriteMovieModel` — offline favorites, synced with TMDB account favorites when logged in
- `RecentSearchModel` — search history (create/read/delete)
- `CachedMovieModel` — offline cache of home sections with TTL (read + auto-purge = update/delete)
- `@Model` + `ModelContainer` configured per environment (in-memory container for tests — nice touch)

Repository pattern hides whether data came from network or SwiftData → shows offline-first thinking.

---

## 6. Environment Configuration (Dev / Staging / Test / Live)

- **4 `.xcconfig` files**: `Dev.xcconfig`, `Staging.xcconfig`, `Test.xcconfig`, `Live.xcconfig`
  - `API_BASE_URL`, `TMDB_API_KEY`, `APP_NAME` (e.g. "TMDB Dev"), `BUNDLE_ID_SUFFIX` (`.dev`, `.staging`), `LOG_LEVEL`, `IMAGE_BASE_URL`
- **4 schemes** mapped to 4 build configurations; values flow xcconfig → Info.plist → `CoreEnvironment.AppEnvironment` (type-safe reader, crashes early on missing keys in debug).
- Different bundle IDs + app icons per env (badge overlay "DEV"/"STG") — installs side by side, very demo-friendly.
- Secrets hygiene: real API key lives in a git-ignored `Secrets.xcconfig` (with a committed `Secrets.example.xcconfig`) — later injected by CI instead. Reviewers *always* check for hardcoded keys.
- TMDB has one base URL in reality, so Dev/Staging can point at the same host with different logging/feature flags — the point is demonstrating the setup, and Test can point at a local mock server (see Testing).

---

## 7. Core Features (MVP)

### Auth (TMDB flows)
- **Login with TMDB account**: request token → user approval (in-app `SFSafariViewController`/`ASWebAuthenticationSession`) → create session → store in Keychain
- **Guest session** (browse without account, limited features)
- **Logout**: delete session remotely + wipe Keychain + clear user-scoped SwiftData
- Session validation on app launch

### Tab Bar (4 tabs + more later)
1. **Home** — horizontally scrolling sections: Trending (day/week toggle), Now Playing, Popular, Upcoming, Top Rated. Parallel fetching with `TaskGroup` (great concurrency demo). Pull-to-refresh, skeleton shimmer loading, pagination.
2. **Search** — `AsyncStream`-debounced search-as-you-type, recent searches (SwiftData), empty/error states.
3. **Favorites** — grid of favorites; works offline via SwiftData, syncs to TMDB account when authenticated; swipe to remove.
4. **Profile** — avatar/username from TMDB account, stats (favorites count), settings (theme, language), environment indicator in debug builds, logout.

### Movie Details (pushed from any tab)
- Backdrop header with stretchy scroll effect, rating ring, genres, overview
- Cast carousel, trailers (YouTube via `WKWebView`/link out), similar & recommended movies
- Favorite/watchlist toggle with optimistic UI update + rollback on failure (nice async/await error-handling demo)

---

## 8. Extra Features — ALL CONFIRMED IN SCOPE ✅

**High impact / low cost:**
1. **Watchlist** (TMDB supports it natively) — second synced collection, reuses favorites plumbing
2. **Deep linking + Universal Links** — proves the coordinator architecture pays off
3. **Localization: English + Arabic with full RTL support** — rare in portfolios and very relevant for your market
4. **Dark/Light theme + app icon alternates** — cheap, visual, lives in CoreUI
5. **Offline mode banner + cached browsing** — shows repository pattern maturity

**Medium effort:**
6. **TV Shows tab or segmented Home** (TMDB TV endpoints) — shows generic reuse of your layers
7. **Person/Actor details screen** — filmography, deep navigation graphs
8. **Home Screen Widget (WidgetKit)** — "Trending today" widget sharing data via App Group + SwiftData
9. **Rating movies** (POST rating to TMDB) — demonstrates writes, not just reads
10. **Advanced search filters** — genre, year, rating (TMDB Discover endpoint)

**Wow factor:**
11. **Live Activities / Dynamic Island** — e.g. "movie releasing today" countdown
12. **App Intents / Siri Shortcuts** — "Show my watchlist"
13. **Accessibility pass** — VoiceOver labels, Dynamic Type; interviewers increasingly probe this
14. **Snapshot tests for CoreUI components**

---

## 9. Testing Strategy

- **Unit tests (Swift Testing framework, not XCTest — modern signal):** use cases, ViewModels (with mocked repos from SharedTestSupport), mappers, KeychainManager (with test service name), environment reader
- **SwiftData tests:** in-memory `ModelContainer`
- **Networking tests:** `URLProtocol` stub — no real network
- **UI tests:** critical paths only (login flow, add favorite) against the **Test** scheme pointing at a local mock server or stubbed layer
- Target: meaningful coverage on Domain + ViewModels (~80%), not vanity coverage

---

## 10. Phased Roadmap

**Phase 0 — Foundation (week 1)**
Project + workspace setup, all SPM packages scaffolded, xcconfigs + schemes, CoreNetworking client, CoreEnvironment, design tokens in CoreUI, DI approach decided.

**Phase 1 — Auth + Shell (week 2)**
KeychainManager, TMDB auth flow (login/guest/logout), AppCoordinator with auth gate, tab bar shell with placeholder screens.

**Phase 2 — Home + Details (weeks 3–4)**
Home sections with TaskGroup fetching, pagination, skeletons; Movie Details full screen; image caching layer.

**Phase 3 — Search + Favorites + Profile (week 5)**
Debounced search + recent searches; SwiftData favorites + TMDB sync; Profile screen.

**Phase 4 — Synced collections + discovery (weeks 6–7)**
Watchlist (reuses favorites plumbing), movie ratings (POST), advanced search filters via Discover endpoint, offline mode banner + cached browsing.

**Phase 5 — TV Shows + People (weeks 8–9)**
TV Shows (segmented Home or 5th tab) — proves layer reuse with a second media type; Person/Actor details with filmography and deep navigation graphs.

**Phase 6 — Platform integration (weeks 10–11)**
Deep linking + Universal Links (coordinator payoff), WidgetKit "Trending today" widget (App Group + shared SwiftData), App Intents / Siri Shortcuts, Live Activities / Dynamic Island countdown.

**Phase 7 — Polish + i18n + a11y (week 12)**
EN + AR localization with full RTL, dark/light theme + alternate app icons, accessibility pass (VoiceOver, Dynamic Type), snapshot tests for CoreUI, empty/error states everywhere.

**Phase 8 — Quality + CI/CD (ongoing)**
Test suite completion, SwiftLint + SwiftFormat, GitHub Actions (build + test on PR, per-env builds), Fastlane lanes: `lint`, `test`, `beta` (TestFlight for Staging), `release` (Live), screenshot automation, code signing via `match`.

**README** — architecture diagram, module graph, screenshots/GIFs, setup instructions, decisions log ("why Coordinator", "why no Combine"). For a portfolio repo, the README is half the value.

---

## 11. Notes on the TMDB API

- Base: `https://api.themoviedb.org/3` — images: `https://image.tmdb.org/t/p/{size}`
- Prefer **v4 Read Access Token** in the `Authorization: Bearer` header over the v3 `api_key` query param (cleaner, more modern)
- Auth endpoints: `/authentication/token/new` → approval URL → `/authentication/session/new`; guest: `/authentication/guest_session/new`
- Fetch `/configuration` once at launch for image sizes; cache it
- Respect rate limits with a simple retry-after policy in the client interceptor

---

*Next steps: confirm the extra features you want in scope, then we start Phase 0 — I can generate the full package scaffolding, xcconfig files, and the networking client whenever you're ready.*
