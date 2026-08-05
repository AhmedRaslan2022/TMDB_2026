---
name: swift-reviewer
description: >
  Reviews Swift, SwiftUI, and Swift Concurrency code for correctness, modern
  API usage, layer-boundary violations, and testability. Use when reading,
  writing, or reviewing Swift code — a working diff, a single file, a package,
  or a pull request. Reports only genuine problems with before/after fixes.
license: MIT
metadata:
  version: "1.0"
  adapted-from: >
    twostraws/SwiftUI-Agent-Skill, twostraws/Swift-Concurrency-Agent-Skill,
    AvdLee/Swift-Testing-Agent-Skill, efremidze/swift-architecture-skill
---

# Swift Reviewer

Review Swift code for correctness, modern API usage, and adherence to this
project's conventions. Report only genuine problems — do not nitpick, do not
restyle working code, and do not invent findings to look thorough.

`CLAUDE.md` is the contract and wins over any general Swift advice below.

## Review process

Load only the reference files relevant to what changed. A full review runs all
of them; a two-file diff usually needs one or two.

1. Grep for known-dangerous patterns first — `references/hotspots.md` tells you
   what to search for and what each hit means.
2. State ownership, `@Observable`, and ViewModel shape → `references/observation-state.md`.
3. Concurrency correctness, actor isolation, `Sendable`, cancellation → `references/concurrency.md`.
4. Layer boundaries, DI, navigation ownership, module graph → `references/architecture.md`.
5. SwiftUI view composition, navigation, accessibility, performance → `references/swiftui.md`.
6. Test presence and quality → `references/testing.md`.
7. Secrets, Keychain, logging, and privacy → `references/security.md`.

## Core instructions

- **Read whole files, not hunks.** Judge code in the context it will run in;
  follow the types a diff touches into their definitions.
- Target iOS 17+, Swift 5.10+ with strict concurrency. SwiftUI only.
- Observation framework only: `@Observable` / `@Bindable`. `ObservableObject`,
  `@Published`, `@StateObject`, `@EnvironmentObject` are all violations here.
- async/await, `Task`, `TaskGroup`, `AsyncSequence`, actors. Combine and
  completion handlers are violations in new code.
- Prefer structured concurrency (task groups) over unstructured `Task {}`.
- Never suggest `@unchecked Sendable` to silence a compiler error — it hides
  the race instead of fixing it. Prefer actors, value types, or `sending`.
  The only legitimate use is a type with provably correct internal locking.
- Do not introduce third-party dependencies. URLSession only for networking.
- Prefer the smallest change that fixes the problem. Do not demand rewrites
  for taste, and do not flag pre-existing code the diff merely moved.
- Severity is conservative: **Critical** means a crash, data loss, leaked
  secret, or a race — not "I would have written it differently".

## Grouping and severity

Multiple sites sharing one root cause are **one finding with examples**, not
one finding per site. Seven ViewModels missing `@MainActor` is a single
finding citing three of them.

| Severity | Meaning |
| --- | --- |
| Critical | Crash, data loss, race, or leaked secret. Blocks merge. |
| High | Violates a hard rule in `CLAUDE.md`, or a real bug on a plausible path. Blocks merge. |
| Medium | Correct but fragile, untested, or misleading. Fix before merge if cheap. |
| Low | Polish. Non-blocking. |

## Output format

Organize findings by file. For each issue:

1. State the file and relevant line(s) as `Path/File.swift:42`.
2. Name the rule being violated.
3. Show a brief before/after fix — minimal, not a rewrite of the file.

Skip files with no issues. End with a prioritized summary, then one line
listing the rule areas you checked clean so the caller knows your coverage.

### Example output

#### Packages/Features/Sources/FeatureHome/Presentation/HomeViewModel.swift

**Line 22: ViewModel exposes loose flags instead of one exhaustive `ViewState`.**

```swift
// Before
@Observable @MainActor final class HomeViewModel {
    var isLoading = false
    var movies: [Movie] = []
    var errorMessage: String?
}

// After
@Observable @MainActor final class HomeViewModel {
    enum ViewState { case idle, loading, loaded([Movie]), error(String) }
    private(set) var state: ViewState = .idle
}
```

**Line 48: Unstructured tasks in a loop lose cancellation propagation.**

```swift
// Before
for id in ids {
    Task { await load(id) }
}

// After
await withTaskGroup(of: Void.self) { group in
    for id in ids {
        group.addTask { await self.load(id) }
    }
}
```

#### Summary

1. **Architecture (high):** `HomeViewModel:22` breaks the single-`ViewState`
   rule; three flags can encode "loading and errored" at once.
2. **Concurrency (medium):** `HomeViewModel:48` detaches work from the parent
   task, so leaving the screen does not cancel in-flight loads.

**Checked clean:** DI wiring, layer imports, secret handling, test coverage
for the new mapper.

End of example.

## Verification checklist

Before returning a report:

1. Every Critical and High finding was confirmed by opening the cited lines —
   no finding rests on a grep hit alone.
2. Findings sharing a root cause are grouped.
3. Each finding names a rule and shows a concrete fix.
4. Nothing flagged is pre-existing code the diff only moved or reindented.
5. If the code is clean, say so plainly with the checked-clean line.

## References

- `references/hotspots.md` — grep targets: dangerous patterns and what to check for each.
- `references/observation-state.md` — `@Observable`, `@Bindable`, ViewState modeling, ownership.
- `references/concurrency.md` — actor isolation, `Sendable`, structured concurrency, cancellation.
- `references/architecture.md` — Clean Architecture layers, DI, coordinators, module graph.
- `references/swiftui.md` — views, navigation, accessibility, performance, modern API.
- `references/testing.md` — Swift Testing patterns, URLProtocol stubs, in-memory SwiftData.
- `references/security.md` — secrets, Keychain, logging, privacy.
