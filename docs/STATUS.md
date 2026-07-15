# Project Status

Task checklist mirroring `docs/SPRINTS.md`. One line per deviation/decision.

> **Note:** `docs/PLAN.md` does not exist in this repo — `TMDB-App-Plan.md` was deleted before Sprint 0 started. Architecture rules in `CLAUDE.md` serve as the plan of record until a PLAN.md is added.

## Sprint 0 — Foundation & Tooling

- [x] 0.1 Create Xcode workspace + thin app target
- [x] 0.2 Scaffold all SPM packages with dependency graph wired
- [x] 0.3 SwiftLint + SwiftFormat, pre-commit hook, .editorconfig
- [x] 0.4 Create 4 xcconfig files + 4 build configs + 4 schemes
- [ ] 0.5 Secrets.xcconfig (git-ignored) + Secrets.example.xcconfig committed
- [ ] 0.6 CoreEnvironment.AppEnvironment — type-safe config reader
- [ ] 0.7 Per-env bundle IDs, app names, DEV/STG icon badge
- [ ] 0.8 CoreNetworking: APIClient, Endpoint protocol, request builder, error mapping
- [ ] 0.9 Auth interceptor (v4 Bearer) + `/configuration` smoke test
- [ ] 0.10 CoreUI design tokens + base components stub
- [ ] 0.11 DI approach decided + AppContainer skeleton
- [ ] 0.12 README v1

### Sprint 0 Definition of Done
- [ ] All 4 schemes build & run a blank screen
- [ ] `/configuration` returns 200 in a debug log
- [ ] Lint passes
- [ ] Repo history clean

### Decisions / Deviations
- 0.2: Three manifests (Core, Features, Shared) with multiple library products each, matching the CLAUDE.md module map — not 13 separate packages. Swift tools 6.0 (strict concurrency), platform iOS 17.
- 0.3: Pre-commit hook is versioned in `.githooks/`; enable per clone with `git config core.hooksPath .githooks`. Trailing commas mandatory (SwiftFormat + SwiftLint agree).
- 0.4: Debug/Release replaced outright by Dev/Staging/Test/Live (not added alongside). Deployment target lowered from template 26.4 to iOS 17.0. Known SwiftPM heuristic: custom config names build package deps with release-style codegen — accepted.
- Sprint backlog file moved from repo root (`TMDB-App-Sprints.md`) to `docs/SPRINTS.md` per CLAUDE.md.
- No git remote configured yet → per-task branches are squash-merged into `develop` locally; PRs start once a remote exists.

## Sprint 1 — Persistence & App Shell
- [ ] 1.1 – 1.9 (not started)

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
