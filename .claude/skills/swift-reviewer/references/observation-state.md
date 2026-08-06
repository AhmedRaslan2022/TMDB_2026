# Observation and state modeling

iOS 17+ means the Observation framework is the only state system in this
codebase. `ObservableObject`, `@Published`, `@StateObject`, and
`@EnvironmentObject` are hard violations.

## ViewModel shape

Every ViewModel is `@Observable @MainActor final class`, exposes exactly one
exhaustive `ViewState` enum, and keeps its setters private.

```swift
// Before — flags that can encode impossible combinations
@Observable final class MovieListViewModel {
    var isLoading = false
    var movies: [Movie] = []
    var error: Error?
}

// After
@Observable @MainActor final class MovieListViewModel {
    enum ViewState: Equatable {
        case idle
        case loading
        case loaded([Movie])
        case error(String)
    }

    private(set) var state: ViewState = .idle

    private let fetchMovies: FetchMoviesUseCase

    init(fetchMovies: FetchMoviesUseCase) {
        self.fetchMovies = fetchMovies
    }
}
```

Findings to raise:

- More than one source of truth for the same screen state (a `state` enum
  *and* a stray `isLoading`).
- A `ViewState` with an `.error` case that carries a raw `Error` — the View
  would have to interpret it. Carry a presentable message or a typed
  domain error the View can switch over.
- Missing `@MainActor`. Without it, mutations from a background continuation
  race the render pass.
- `var` state that the View can write. Use `private(set)` plus an intent
  method (`func retry()`), not direct mutation from the body.

## Ownership in views

```swift
// Correct: the view owns the lifetime
struct MovieListView: View {
    @State private var viewModel: MovieListViewModel

    init(viewModel: MovieListViewModel) {
        _viewModel = State(initialValue: viewModel)
    }
}

// Correct: the parent owns it, the child edits it
struct FiltersView: View {
    @Bindable var viewModel: MovieListViewModel
}

// Wrong: recreated on every parent re-render, losing all state
struct MovieListView: View {
    private var viewModel = MovieListViewModel(...)
}
```

Rules:

- `@State` for the owner, `@Bindable` for a child that needs two-way bindings,
  a plain `let` for a child that only reads.
- Never construct a ViewModel in a `body`. Construction belongs to the
  coordinator or composition root.
- `@Environment` carries app-wide services; it does not replace injection of
  use cases into a ViewModel.

## Observation tracking gotchas

`@Observable` tracks the properties actually *read during* `body`. Two
consequences worth flagging:

```swift
// Reading the whole array in body means any element change redraws everything.
ForEach(viewModel.movies) { movie in
    MovieRow(movie: movie)          // fine: MovieRow takes a value
}

// Passing the ViewModel down makes the child observe the whole object.
ForEach(viewModel.movies) { movie in
    MovieRow(viewModel: viewModel, id: movie.id)   // finding: over-observation
}
```

- Reads performed inside a `Task` or a closure that runs after `body` are not
  tracked — code relying on that is a bug, not an optimization.
- A computed property that touches many stored properties widens the
  dependency set for every view that reads it.

## Async work in a ViewModel

```swift
@MainActor
func load() async {
    state = .loading
    do {
        let movies = try await fetchMovies()
        state = .loaded(movies)
    } catch is CancellationError {
        state = .idle                       // do not surface cancellation as an error
    } catch {
        state = .error(error.localizedDescription)
    }
}
```

Flag: swallowing `CancellationError` into `.error` (produces a phantom error
banner when the user simply navigated away), and `Task {}` started in `init`
(untestable and un-cancellable — start work from `.task { await vm.load() }`).
