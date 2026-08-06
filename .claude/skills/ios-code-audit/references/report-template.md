# CODE_AUDIT.md template

Copy this skeleton verbatim. Keep the twelve top-level numbers even when a
section is empty — write `_No findings._` rather than deleting the heading, so
cross-references from earlier audits keep resolving.

```markdown
# Code Audit — <repo> @ <short-sha>

**Date:** <YYYY-MM-DD>
**Scope:** <N> Swift files, <M> lines across <packages>
**Build:** <scheme> — <clean | N warnings | failed>
**Findings:** <C> Critical, <H> High, <M> Medium, <L> Low

## 1. Executive summary

The 5–10 highest-impact items, one line each, each linking its section:

1. Actor reentrancy in the image cache causes duplicate downloads — §3.2
2. Session token written to UserDefaults on the legacy login path — §6.1
...

## 2. Quick wins

Findings fixable in under 30 minutes each, with their section references.
Ordered by (impact ÷ effort), so the list can be worked top-down.

## 3. Concurrency

Actor isolation, reentrancy, `Sendable`, cancellation, `@unchecked Sendable`,
GCD left in feature code, unstructured tasks.

## 4. API modernity

Deprecated SwiftUI/Foundation API, `ObservableObject` holdouts, Combine
remnants, completion-handler APIs that should be `async`.

## 5. Bugs and logic errors

Force unwraps on reachable paths, off-by-one, wrong comparison, unhandled
enum cases, error paths that silently succeed, retain cycles.

## 6. Security

Secrets, Keychain usage and accessibility classes, logging of sensitive
values, TLS handling, storage placement.

## 7. Performance

Work in `body`, repeated formatter construction, unbounded caches, N+1
network calls, main-thread decoding, image handling.

## 8. SwiftUI and UI

View decomposition, identity and diffing, navigation ownership,
accessibility, Dynamic Type, hardcoded user-facing strings.

## 9. Architecture and dead code

Layer violations, DTO leaks, DI bypasses, cross-feature imports, duplicated
helpers that belong in Core, unreferenced types, commented-out code.

## 10. Cross-cutting recommendations

Themes rather than sites: patterns worth a follow-up task, a lint rule that
would have caught a whole class of finding, a missing test seam.

## 11. What was NOT audited

Explicit list. Build settings, third-party internals, Instruments profiling,
localization wording, visual design, and any package or directory skipped —
with the reason.

## 12. Verification

For each Critical and High finding, the exact line range read to confirm it:

| Finding | File | Lines read | Confirmed |
| --- | --- | --- | --- |
| 3.2 | Packages/Core/CoreUI/Sources/CoreUI/ImageCache.swift | 28–52 | yes |
| 6.1 | Packages/Core/CoreStorage/Sources/CoreStorage/SessionStore.swift | 14–39 | yes |
```

## Re-auditing

On a second pass over the same repo:

- Keep every existing number. A fixed finding becomes
  `### 3.2 _RESOLVED_ <original title>` with a one-line note naming the commit.
- A finding that turns out to be wrong becomes `### 3.2 _WITHDRAWN_` with the
  reason — do not delete it, because someone may have a ticket pointing at it.
- New findings append at the end of their section with the next free number.
- Update the header counts and re-cut section 1 against current severity.
