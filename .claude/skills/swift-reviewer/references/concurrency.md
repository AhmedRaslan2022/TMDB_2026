# Swift Concurrency review

Target Swift 5.10+ with strict concurrency checking, moving toward Swift 6
language mode. async/await, `Task`, `TaskGroup`, `AsyncSequence`, and actors
only — no Combine, no completion handlers, no GCD in feature code.

## Actor reentrancy

Every `await` inside an actor is a suspension point where other calls can
interleave and mutate state. State read before an `await` may be stale after.

```swift
// Before — two concurrent callers both see nil and both download
actor ImageCache {
    private var items: [URL: Data] = [:]

    func data(for url: URL) async throws -> Data {
        if items[url] == nil {
            items[url] = try await download(url)
        }
        return items[url]!          // also a force unwrap
    }
}

// After — dedupe with an in-flight task map
actor ImageCache {
    private enum Entry { case ready(Data), loading(Task<Data, Error>) }
    private var items: [URL: Entry] = [:]

    func data(for url: URL) async throws -> Data {
        switch items[url] {
        case .ready(let data):
            return data
        case .loading(let task):
            return try await task.value
        case nil:
            let task = Task { try await self.download(url) }
            items[url] = .loading(task)
            do {
                let data = try await task.value
                items[url] = .ready(data)
                return data
            } catch {
                items[url] = nil     // do not cache the failure
                throw error
            }
        }
    }
}
```

Review move: for each `await` in an actor, ask "what did I assume was still
true across this line?" If a check-then-act straddles it, that is a finding.

## Structured over unstructured

```swift
// Before — fan-out that cannot be cancelled or awaited as a unit
for section in sections {
    Task { await load(section) }
}

// After
try await withThrowingTaskGroup(of: Section.self) { group in
    for section in sections {
        group.addTask { try await self.load(section) }
    }
    for try await section in group {
        apply(section)
    }
}
```

- `Task {}` is a code smell anywhere the caller could have been `async`. It is
  legitimate at the boundary between a synchronous context (a SwiftUI action,
  a delegate callback) and async work.
- `Task.detached` drops actor isolation, priority, and task-local values.
  Requires an explicit reason; "it compiled" is not one.
- Unbounded fan-out over a user-controlled collection needs a concurrency
  limit (add tasks up to N, then add one per completion).

## Cancellation

```swift
// Before — keeps working after the screen is gone
func load() async {
    let movies = try? await fetchMovies()
    state = .loaded(movies ?? [])
}

// After
func load() async {
    do {
        let movies = try await fetchMovies()
        try Task.checkCancellation()
        state = .loaded(movies)
    } catch is CancellationError {
        return
    } catch {
        state = .error(error.localizedDescription)
    }
}
```

- Long loops with no `try Task.checkCancellation()` never stop early.
- `try?` around an async call silently swallows `CancellationError` and
  converts a cancelled load into an empty success — a common, quiet bug.
- Work started in `.task {}` is cancelled when the view disappears; work
  started in `Task {}` is not. Flag the mismatch when the intent is per-screen.

## Sendable

```swift
// Before
final class Session: @unchecked Sendable {
    var token: String?              // actually racy
}

// After
actor Session {
    private(set) var token: String?
    func update(_ token: String?) { self.token = token }
}
```

- Never accept `@unchecked Sendable` as a fix for a diagnostic. It is only
  valid for a type whose mutable state is provably guarded (e.g. a `Mutex`),
  and it needs a comment saying so.
- Domain entities should be `struct` + `Sendable`. A reference-type entity
  crossing an isolation boundary is a finding.
- `nonisolated(unsafe)` is the same suppression in a different costume.

## Isolation

- ViewModels: `@MainActor`. Repositories and data sources: `actor` or
  `Sendable` value types. Use cases: usually stateless structs, isolation-free.
- Do not mark a whole repository `@MainActor` to silence errors — it drags
  network parsing onto the main thread.
- `nonisolated` on a computed property that reads isolated state will not
  compile; on one that reads only `let`s it is correct and useful.

## Bridging

```swift
// Wrapping a legacy callback API
func location() async throws -> CLLocation {
    try await withCheckedThrowingContinuation { continuation in
        manager.request { result in
            continuation.resume(with: result)   // exactly once
        }
    }
}
```

Findings: a continuation resumed twice (crash), a continuation that can leak
on an early return (hang), and `withUnsafeContinuation` used where the checked
variant would have caught the bug.

## Async sequences

- Prefer `AsyncStream.makeStream(of:)` over the closure initializer when the
  continuation must escape.
- Always set `onTermination` to tear down the underlying source, or the
  producer outlives its consumer.
- `.buffered` policy matters: the default `.unbounded` grows without limit on
  a fast producer. For UI state, `.bufferingNewest(1)` is usually right.
