# Hotspots — grep targets for review

Run these first. A hit is a *candidate*, never a finding: open the line and
confirm before reporting. Paths assume the repo root.

## Banned frameworks and patterns

```bash
rg -n 'ObservableObject|@Published|@StateObject|@EnvironmentObject' --glob '*.swift'
rg -n '^import Combine|AnyCancellable|PassthroughSubject|CurrentValueSubject' --glob '*.swift'
rg -n 'completion:\s*@escaping|completionHandler' --glob '*.swift'
rg -n 'DispatchQueue\.|dispatchGroup|DispatchSemaphore' --glob '*.swift'
```

| Hit | What it means |
| --- | --- |
| `ObservableObject` family | Hard violation. Must be `@Observable` / `@Bindable`. |
| `import Combine` | Hard violation in new code. Replace with `AsyncStream`/`AsyncSequence`. |
| `@escaping` completion | Hard violation in new code. Convert to `async throws`. |
| `DispatchQueue` | Suspect. Acceptable only in low-level interop; flag in feature code. |

## Crash and correctness risks

```bash
rg -n '!\s*$|\)!|\]!|as!\s' --glob '*.swift' --glob '!*Tests*'
rg -n 'try!|fatalError|preconditionFailure' --glob '*.swift' --glob '!*Tests*'
rg -n 'print\(|NSLog|debugPrint' --glob '*.swift'
rg -n '@unchecked Sendable' --glob '*.swift'
```

- Force unwraps and `try!` outside tests are findings unless immediately
  preceded by a proof the value exists.
- `print` is banned — the CoreUtilities logger is the only output channel.
- `@unchecked Sendable` needs a comment proving internal locking, otherwise
  it is a suppressed race.

## Concurrency

```bash
rg -n 'Task\s*\{' --glob '*.swift'
rg -n 'Task\.detached' --glob '*.swift'
rg -n 'nonisolated\(unsafe\)|@preconcurrency' --glob '*.swift'
rg -n 'Task\.sleep|DispatchQueue.*asyncAfter' --glob '*.swift'
```

- `Task {}` inside a loop → should almost always be a task group.
- `Task.detached` loses isolation, priority, and cancellation — needs a reason.
- `Task.sleep` in a test is a timing-based test; see `testing.md`.
- Any `await` inside an actor method that reads mutable state before *and*
  after → check for a reentrancy bug (`concurrency.md`).

## Layer boundaries

```bash
# Domain must be pure Swift
rg -n '^import (SwiftUI|SwiftData|Foundation)' Packages/Features/Sources/*/Domain
rg -n 'Codable|CodingKeys' Packages/Features/Sources/*/Domain
# Features must not import each other
rg -n '^import Feature' Packages/Features/Sources
# Core must not import Features
rg -n '^import Feature' Packages/Core
# DTOs must not escape Data/
rg -n 'DTO' Packages/Features/Sources/*/Presentation Packages/Features/Sources/*/Domain
```

Every hit here is a hard violation of the module map in `CLAUDE.md`.

## Navigation ownership

```bash
rg -n 'NavigationLink\(destination:' --glob '*.swift'
rg -n '@State.*isPresented|\.sheet\(|\.fullScreenCover\(' Packages/Features
```

Views never push or present directly — routes go through a coordinator. A
`.sheet` bound to view-local `@State` inside a feature is a finding.

## Testability

```bash
rg -n '\.shared\b' --glob '*.swift' --glob '!*Tests*'
rg -n 'URLSession\(|URLSession\.shared' Packages/Features
rg -n '= [A-Z][A-Za-z]*(UseCase|Repository|Impl)\(' --glob '*.swift' --glob '!*Tests*'
```

A concrete dependency constructed inside its consumer is untestable and
violates the DI rule — it must arrive through the initializer as a protocol.

## Secrets

```bash
rg -ni 'bearer [A-Za-z0-9._-]{20,}|api_key=|eyJ[A-Za-z0-9_-]{10,}' --glob '*.swift' --glob '*.xcconfig' --glob '*.plist'
git check-ignore -q Configs/Secrets.xcconfig || echo 'Secrets.xcconfig NOT ignored'
```

Any literal that looks like a token is Critical, including in tests and
fixtures. See `security.md`.
