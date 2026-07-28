# CLAUDE.md — TMDB Showcase App

This file defines the non-negotiable rules for working in this repository. Read it fully before any task. Detailed context lives in `docs/PLAN.md` (architecture plan) and `docs/SPRINTS.md` (sprint backlog) — consult them before starting any sprint or task.

## Project

Portfolio-grade iOS app on the TMDB API. Purpose: demonstrate senior-level iOS skills. Every decision should optimize for **code a reviewer would praise**, not for speed.

- Min iOS: 17.0 · Swift 5.10+ · SwiftUI only · Xcode workspace + local SPM packages
- TMDB API v3 endpoints, authenticated with the **v4 Read Access Token as a `Authorization: Bearer` header** (not the `api_key` query param)

## Hard Architecture Rules (never violate)

1. **Observation framework only.** Use `@Observable` and `@Bindable`. NEVER use `ObservableObject`, `@Published`, `@StateObject`, or `@EnvironmentObject`.
2. **Modern concurrency only.** async/await, `Task`, `TaskGroup`, `AsyncStream`/`AsyncSequence`, actors. NEVER use Combine. NEVER use completion handlers in new code.
3. **Clean Architecture per feature**: `Domain/` (entities, use-case protocols+impls, repository protocols) → `Data/` (DTOs, mappers, data sources, repository impls) → `Presentation/` (ViewModels, Views, Routes).
   - Domain is pure Swift: no Codable, no SwiftData, no SwiftUI, no Foundation networking imports.
   - DTOs never leak past the Data layer; always map to Domain entities.
4. **MVVM**: ViewModels are `@Observable @MainActor final class`, expose state as a single exhaustive `ViewState` enum (`idle / loading / loaded / error`). Views contain no business logic.
5. **Coordinator pattern owns ALL navigation.** Views never push/present directly. Each tab has its own `NavigationStack` bound to a child coordinator; routes are `Hashable` enums; `navigationDestination(for:)` mapping lives in the app target. Sheets/covers are coordinator-driven too.
6. **SPM dependency direction:** `Features → Core` only. A feature package NEVER imports another feature package. Cross-feature navigation goes through coordinators in the app target. `Core` packages never import `Features`.
7. **Dependency injection via protocols.** No singletons except where the OS forces it; use cases and repositories are injected, never instantiated inside consumers.
8. **No third-party networking or reactive libs.** URLSession only. (Image loading: the custom actor-based cache in CoreUI/Networking.)

## Module Map

```
TMDBApp (app target: composition root, AppCoordinator, route wiring only)
Packages/Core:      separate packages — Networking, CoreStorage, CoreModels, CoreUI, CoreUtilities, CoreEnvironment
Packages/Features:  FeatureAuth, FeatureHome, FeatureMovieDetails, FeatureSearch, FeatureFavorites, FeatureProfile (+ FeatureTV, FeaturePerson in Sprint 6)
Packages/Shared:    SharedTestSupport (mocks/stubs — test targets only)
```

New shared code goes in the correct Core package — never duplicated into features, never dumped into the app target.

## Persistence Rules

- **Keychain** (`CoreStorage.KeychainManager`, an actor): session ID, account ID, tokens. Nothing sensitive ever goes in UserDefaults, SwiftData, or source code.
- **SwiftData**: app data CRUD only (FavoriteMovie, RecentSearch, CachedMovie, later Watchlist). `ModelContainer` configured per environment; **in-memory container in tests**.
- Repositories hide the data origin (network vs local). Offline-first where the sprint specifies it.

## Environments & Secrets

- 4 configs/schemes: **Dev, Staging, Test, Live** via xcconfig files → Info.plist → `CoreEnvironment.AppEnvironment` (type-safe reader; missing key = precondition failure in debug).
- Per-env bundle ID suffix, display name, icon badge.
- **Secrets:** real values live ONLY in `Configs/Secrets.xcconfig`, which is git-ignored. `Configs/Secrets.example.xcconfig` is committed with placeholder values. NEVER hardcode the TMDB token anywhere, NEVER commit Secrets.xcconfig, NEVER print secrets in logs, commit messages, or PR descriptions. If Secrets.xcconfig is missing, stop and ask the user to create it from the example file.

## Testing Rules

- Framework: **Swift Testing** (`@Test`, `#expect`) — not XCTest, except UI tests.
- Unit-test every use case, ViewModel, and mapper as they are written — tests land in the SAME PR as the code, not later.
- Networking tests use `URLProtocol` stubs. SwiftData tests use in-memory containers. Keychain tests use a dedicated test service name and clean up after themselves.
- No real network calls in any test.
- A sprint task is not done if its `[test]` items are red or missing.

## Code Style

- SwiftLint + SwiftFormat must pass before every commit (pre-commit hook installs in Sprint 0).
- Naming: `FetchTrendingMoviesUseCase`, `MovieRepository` (protocol) / `MovieRepositoryImpl`, `HomeViewModel`, `HomeRoute`.
- Files > ~300 lines or Views with deeply nested bodies must be decomposed into subviews/extensions (see the `refactor-screen-readable` skill if available).
- Public APIs of Core packages get doc comments. No commented-out code, no `print` (use the CoreUtilities logger), no force unwraps outside tests.
- Strings: user-facing text goes through String Catalogs from day one (full AR localization lands in Sprint 8, but don't create hardcoded-string debt).

## Git Workflow

- **Promotion pipeline** (see `docs/BRANCHING.md`): `develop → test → staging → main`, each hop a PR, each merge minting a versioned build for that environment (`test`=Test, `staging`=Staging→TestFlight, `main`=Live→App Store). `main` is the production (Live) line; the former `live` branch was retired into it.
- Work branches: `sprint-N/task-N.M-short-name` (or `fix/…`, `chore/…`) off `develop`.
- **Conventional commits** (`feat:`, `fix:`, `test:`, `chore:`, `refactor:`, `docs:`). Small, atomic commits.
- One PR per task (or tightly-related task pair), **squash-merged into `develop`**. Promotion PRs (develop→test→staging→main) use **merge commits**, forward-only, one hop at a time. PR description: what/why + which sprint task it closes.
- **Never push directly to `develop`, `test`, `staging`, or `main`** — always open a pull request, including feature work into `develop`. Never force-push a shared branch.
- CI (`.github/workflows/ci.yml`) gates every PR; `release.yml` versions each promotion merge. Branch protection that blocks non-green/direct pushes is an owner-side GitHub setting.

## Sprint Execution Protocol

The backlog is `docs/SPRINTS.md` (Sprints 0–9 with numbered tasks, points, and a Definition of Done per sprint).

For each work session:
1. Read `docs/SPRINTS.md` and `docs/STATUS.md` to find the current sprint and next unchecked task.
2. Announce the task (e.g. "Starting 3.2 — HomeViewModel with TaskGroup"), create its branch.
3. Implement following ALL rules above — including its tests.
4. Run build + full test suite + lint for the affected schemes. Fix everything before proceeding.
5. Update `docs/STATUS.md`: check the task off, note deviations/decisions in one line.
6. Commit, open the PR (or present the diff for review if PRs aren't set up yet).
7. Do NOT start the next task in the same branch. Do NOT skip ahead across sprints.
8. At sprint end, verify the sprint's Definition of Done explicitly, item by item, and record it in `docs/STATUS.md`.

If a task is ambiguous or conflicts with these rules, STOP and ask — do not improvise architecture changes. If `docs/STATUS.md` doesn't exist yet, create it (task checklist mirror of SPRINTS.md).

## When Unsure

Prefer: asking > guessing. Smaller PRs > big-bang PRs. Boring correct code > clever code. The plan documents win over improvisation; this file wins over everything.
