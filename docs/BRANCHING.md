# Branching & Release Promotion

The repo uses a **promotion pipeline**: work flows in one direction through the
four environment branches, every hop is a **pull request**, and every merge
mints a new versioned build for that environment.

```
feature branches ──PR──▶ develop ──PR──▶ test ──PR──▶ staging ──PR──▶ live
   (sprint-N/…)          (dev/       (Test env)   (Staging env)   (Live env)
                          integration)             → TestFlight    → App Store
```

## Branches

| Branch | Environment / scheme | Role |
|--------|----------------------|------|
| `sprint-N/task-N.M-…`, `chore/…`, `fix/…` | — | short-lived work branches, off `develop` |
| `develop` | Dev (`TMDB-Dev`) | integration line; features land here first |
| `test` | Test (`TMDB-Test`) | first promotion; QA build |
| `staging` | Staging (`TMDB-Staging`) | pre-prod; TestFlight (`fastlane beta`) |
| `live` | Live (`TMDB-Live`) | production; App Store (`fastlane release`) |

`main` is superseded by `live` as the production line and is no longer a release
target.

## Rules

- **No direct pushes** to `develop`, `test`, `staging`, or `live`. Everything
  goes through a pull request — including feature work merging into `develop`.
- Promotions only move **forward** and only **one hop at a time**:
  `develop → test → staging → live`. Never PR straight from `develop` to
  `staging`/`live`.
- Conventional commits; feature PRs are **squash-merged** into `develop`.
  Promotion PRs (develop→test, etc.) are **merge commits** (not squash), so the
  branches share history and diffs stay clean.
- Never force-push a shared branch.

## What each merge does

- **PR opened** into any of these branches → `.github/workflows/ci.yml` runs the
  gate (SwiftFormat + SwiftLint, unit tests, Test-scheme build/test, per-env
  build matrix). The PR can't be merged until it's green (enforced by branch
  protection — see below).
- **PR merged** into `test` / `staging` / `live` → `.github/workflows/release.yml`
  mints a new version for that environment:
  1. build number = the GitHub Actions run number (unique per merge — no
     commit-back, no loop);
  2. builds the environment's scheme with that version;
  3. tags `‹env›-v‹marketing›-build.‹n›` and creates a GitHub Release
     (`live` is a full release, the others are pre-releases);
  4. for `staging`/`live`, runs `fastlane beta` / `fastlane release` **when the
     App Store Connect + match secrets are configured** — otherwise it skips
     with a warning and the version/tag/release are still created.

## One-time repo setup (owner)

These are GitHub settings, not files — the automation above can't set them:

1. **Actions secret** `TMDB_ACCESS_TOKEN` (used by every build).
2. **Branch protection** on `develop`, `test`, `staging`, `live`: require a PR,
   require the CI checks to pass, and disallow direct pushes. This is what makes
   "no direct push / PR-only" actually enforced.
3. For real distribution, add the signing secrets from `fastlane/SETUP.md`
   (`FASTLANE_APPLE_ID`, `MATCH_GIT_URL`, `MATCH_PASSWORD`, `ASC_KEY_ID`,
   `ASC_ISSUER_ID`, `ASC_KEY`). Until then, `staging`/`live` merges version and
   tag but skip the upload.
