# Testing review

Framework: **Swift Testing** (`@Test`, `#expect`, `#require`). XCTest only for
UI automation (`XCUIApplication`) and performance metrics.

Tests land in the **same PR** as the code. A diff that adds a use case,
ViewModel, or mapper without tests is a High finding — "tests to follow" is
not a plan.

## Presence

Check the diff contains tests for every:

- use case (happy path + each error path it maps),
- ViewModel (each `ViewState` transition, including cancellation),
- mapper / DTO → domain conversion (including missing and malformed fields),
- repository decision logic (cache hit vs network, offline fallback).

## Assertion quality

```swift
// Before — cannot fail
@Test func loadsMovies() async {
    let sut = HomeViewModel(fetchMovies: FetchMoviesUseCaseMock())
    await sut.load()
    #expect(sut.state != nil)
}

// After
@Test func loadEmitsLoadedWithMappedMovies() async throws {
    let useCase = FetchMoviesUseCaseMock(result: .success([.fixture(id: 7)]))
    let sut = HomeViewModel(fetchMovies: useCase)

    await sut.load()

    let movies = try #require(sut.state.loadedValue)
    #expect(movies.map(\.id) == [7])
}
```

- `#expect` is the default; `#require` when later lines depend on the value.
  `#expect(optional != nil)` followed by a force unwrap is a finding.
- Assertions on `!= nil`, `> 0`, or `.isEmpty == false` alone rarely pin
  behavior. Assert the actual value.
- One behavior per test. A test named `testEverything` with eight `#expect`s
  gives no signal about which behavior broke.
- Repetitive `testCaseA/testCaseB/testCaseC` → one `@Test(arguments:)`.

## Async and determinism

- No `Task.sleep` to "wait for" state. Await the operation directly, or inject
  a clock. Timing-based tests are flaky by construction.
- No real network. `URLProtocol` stubs are the only way networking is
  exercised — flag any test that could hit the wire.
- Tests run in parallel by default. Shared mutable state between tests is the
  usual cause of "passes alone, fails in suite". Fix isolation first;
  `.serialized` is a transition step with a stated reason, not a fix.
- `withKnownIssue` keeps a temporarily-broken test reporting signal.
  `.disabled` rots silently — prefer the former, and require a `.bug()` link.

## SwiftData

Tests use an in-memory `ModelContainer`.

```swift
private func makeContainer() throws -> ModelContainer {
    try ModelContainer(
        for: FavoriteMovie.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
}
```

**Known trap in this repo:** SwiftData tests inside a package target crash when
they touch `container.mainContext`. Construct the context explicitly instead:

```swift
let container = try makeContainer()
let context = ModelContext(container)      // not container.mainContext
```

Flag any package test reaching for `mainContext`.

## Keychain

Keychain tests use a dedicated test service name and clean up in a `deinit` or
a `defer`. A test that writes to the production service name pollutes the
developer's login keychain — Critical, because it leaks across runs.

## Mocks

- Test doubles live in `SharedTestSupport`, never in a production target and
  never duplicated per feature.
- A mock that returns a fixed value regardless of input hides argument bugs.
  Record the received arguments and assert on them when the call shape matters.
- Prefer stub structs conforming to the protocol over subclassing a concrete
  implementation.
