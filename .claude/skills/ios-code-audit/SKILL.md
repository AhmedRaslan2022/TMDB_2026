---
name: ios-code-audit
description: >
  Audits a whole Swift/iOS codebase or package — not a diff — for bugs, dead
  code, concurrency hazards, deprecated APIs, security gaps, and architecture
  drift, and writes a numbered CODE_AUDIT.md with file:line citations. Use for
  "audit the codebase", "what technical debt do we have", end-of-sprint health
  checks, or before a portfolio review. For reviewing a branch diff, use
  swift-reviewer instead.
license: MIT
metadata:
  version: "1.0"
  adapted-from: jazzychad/ios-code-audit, twostraws Swift agent skills
---

# iOS Code Audit

Produce one navigable `CODE_AUDIT.md` at the repo root: a prioritized,
numbered inventory of real problems with exact citations. This is a survey of
existing code, so the bar is different from a diff review — pre-existing
issues are in scope, but the report must stay small enough to act on.

## Operating principles

- **Verification first.** Every Critical and High finding is confirmed by
  opening the cited lines. A grep hit is a lead, not a finding. Overstated
  severity destroys the report's usefulness faster than a missed issue.
- **Group by root cause.** Seven ViewModels missing `@MainActor` is one
  finding with three cited examples, not seven findings.
- **Conservative severity.** Critical means crash, data loss, race, memory
  corruption, or exposed secret. Nothing else.
- **Cap the output.** 50–100 findings maximum. If you have more, you are
  reporting style preferences — raise the bar and re-cut.
- **Stable numbering.** Sections are `## 1.`–`## 12.`, findings are `### N.M`.
  On re-audit, a resolved finding becomes `### N.M _RESOLVED_` — never
  renumber survivors, because people cite these numbers in tickets.

## Workflow

### 1. Scope

```bash
find . -name '*.swift' -not -path '*/.build/*' -not -path '*/Derived/*' | wc -l
find . -name '*.swift' -not -path '*/.build/*' -not -path '*/Derived/*' \
  -exec wc -l {} + | sort -rn | head -30
```

Record the file count, total lines, and the largest files — hot spots cluster
in the biggest files. Note which packages exist so section 11 can state what
you did not cover.

### 2. Compiler truth

Warnings are the cheapest real findings available. Build the affected schemes
and collect every warning before reading any code:

```bash
xcodebuild -workspace TMDB.xcworkspace -scheme TMDB-Dev \
  -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 \
  | rg 'warning:|error:' | sort -u
```

Deprecation and `Sendable` warnings map straight into sections 3 and 4.
If the build fails, fix nothing — report the failure as finding 1.1 and audit
statically.

### 3. Focused passes

Run these as separate passes so each one keeps a narrow lens. Use the
`swift-reviewer` skill's reference files as the rule source for each:

| Pass | Lens | Rules from |
| --- | --- | --- |
| Concurrency | actor reentrancy, `Sendable`, cancellation, `@unchecked` | `swift-reviewer/references/concurrency.md` |
| State | `@Observable` misuse, ViewState modeling, ownership | `.../observation-state.md` |
| Architecture | layer imports, DTO leaks, DI, navigation ownership | `.../architecture.md` |
| SwiftUI | deprecated API, body logic, accessibility, performance | `.../swiftui.md` |
| Security | secrets, Keychain, logging, TLS | `.../security.md` |
| Tests | missing coverage, assertions that cannot fail, flakiness | `.../testing.md` |
| Dead code | unreferenced types, unused params, commented-out blocks | below |

Dead-code technique: for each declared type, `rg -w 'TypeName'` and check for
hits outside its own file and its test. Internal types with a single
declaration site are candidates; `public` API in a Core package is not dead
just because the app has not used it yet — say so rather than flagging it.

### 4. Verify

For every Critical and High finding, open the exact lines and record the range
in section 12. If reading the code disproves the claim, delete the finding —
do not downgrade it to Medium to save face.

### 5. Write the report

Use `references/report-template.md` for the exact skeleton.

## Severity

| Severity | Meaning |
| --- | --- |
| Critical | Crash, data loss, race, memory corruption, exposed secret |
| High | Hard-rule violation from `CLAUDE.md`, or a bug on a plausible user path |
| Medium | Fragile, untested, or misleading; will cost time later |
| Low | Polish, naming, minor duplication |

## Finding format

```markdown
### 3.2 Actor reentrancy in ImageCache allows duplicate downloads

**Severity:** High
**Sites:** `Packages/Core/CoreUI/Sources/CoreUI/ImageCache.swift:34`
(also `:58`, `Networking/Sources/Networking/RequestCache.swift:21`)

Check-then-act straddles an `await`, so two concurrent callers both observe
an empty cache and both download.

**Fix:** store an in-flight `Task` in the cache dictionary and await it on the
second call.
```

Every finding needs: a one-line title naming the defect, severity, at least
one `file:line`, a sentence on why it matters, and a concrete fix direction.
No finding may be phrased as "consider possibly reviewing".

## Out of scope — state this in section 11

Build-setting tuning, third-party internals, Instruments-based performance
profiling (requires traces this audit cannot produce), localization wording
quality, and design/visual review. Naming what you did not look at is what
makes the report trustworthy.

## References

- `references/report-template.md` — the twelve-section `CODE_AUDIT.md` skeleton.
