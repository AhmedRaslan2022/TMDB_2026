# Architecture and boundaries

The module map from `CLAUDE.md`:

```
TMDBApp                composition root, AppCoordinator, route wiring only
Packages/Core          Networking, CoreStorage, CoreUI, CoreKit
                       (CoreModels, CoreUtilities, CoreEnvironment)
Packages/Features      FeatureAuth, FeatureHome, FeatureMovieDetails,
                       FeatureSearch, FeatureFavorites, FeatureProfile
Packages/Shared        SharedTestSupport (test targets only)
```

Dependency direction is one-way: **Features → Core**. A feature never imports
another feature; Core never imports a feature.

## Layer rules per feature

```
FeatureX/
  Domain/         entities, use-case protocols + impls, repository protocols
  Data/           DTOs, mappers, data sources, repository impls
  Presentation/   ViewModels, Views, Routes
```

| Layer | May import | Must never contain |
| --- | --- | --- |
| Domain | Swift stdlib only | Codable, SwiftData, SwiftUI, URLSession |
| Data | Domain, Networking, CoreStorage | SwiftUI, ViewModels |
| Presentation | Domain, CoreUI | DTOs, URLSession, SwiftData models |

```swift
// Before — DTO leaks into the domain and into the ViewModel
struct MovieDTO: Decodable, Identifiable { ... }
@Observable @MainActor final class HomeViewModel {
    private(set) var movies: [MovieDTO] = []
}

// After — DTO stops at the Data layer
struct MovieDTO: Decodable {
    func toDomain() -> Movie { Movie(id: id, title: title, ...) }
}
@Observable @MainActor final class HomeViewModel {
    private(set) var state: ViewState = .idle   // .loaded([Movie])
}
```

Common findings:

- `Movie: Codable` in `Domain/` — the domain entity is now shaped by the wire
  format, and a TMDB field rename becomes a domain change.
- A repository protocol declared in `Data/` instead of `Domain/`. The protocol
  belongs to the layer that *consumes* it, so the dependency points inward.
- A use case that is a pass-through with no logic. Acceptable — it keeps the
  boundary stable — but flag if it is doing mapping that belongs in Data.
- A ViewModel calling a repository directly, skipping the use case, when the
  feature's other screens go through use cases. Inconsistent boundaries are
  worse than either choice made uniformly.

## Dependency injection

Every dependency arrives through the initializer as a protocol. No singletons
except where the OS forces one, no service locators, no default arguments that
construct a concrete production type.

```swift
// Before — untestable, and a network call in a unit test
@Observable @MainActor final class SearchViewModel {
    private let repository = MovieRepositoryImpl(session: .shared)
}

// After
@Observable @MainActor final class SearchViewModel {
    private let searchMovies: SearchMoviesUseCase

    init(searchMovies: SearchMoviesUseCase) {
        self.searchMovies = searchMovies
    }
}
```

Flag `init(useCase: FetchMoviesUseCase = FetchMoviesUseCaseImpl())` — a
default value pins the concrete type into every call site and makes the
"injection" cosmetic.

## Navigation

The coordinator owns all navigation. Views never push or present.

```swift
// Before — the view knows about destinations
NavigationLink(destination: MovieDetailsView(id: movie.id)) {
    MovieRow(movie: movie)
}

// After — the view reports an intent; the coordinator decides
Button {
    coordinator.show(.movieDetails(id: movie.id))
} label: {
    MovieRow(movie: movie)
}
```

- Routes are `Hashable` enums per feature; `navigationDestination(for:)`
  mapping lives in the app target, not in the feature package.
- Each tab has its own `NavigationStack` bound to a child coordinator.
- Sheets and full-screen covers are coordinator-driven too — a `.sheet`
  bound to view-local `@State` inside a feature is a violation.
- Cross-feature navigation goes through the app target. A feature reaching
  for another feature's route type is the import violation in disguise.

## Where new code goes

- Shared UI → `CoreUI`. Shared models → `CoreKit/CoreModels`. Logging,
  formatters, extensions → `CoreKit/CoreUtilities`. Config reads →
  `CoreKit/CoreEnvironment`. Networking primitives → `Networking`.
  Keychain/SwiftData → `CoreStorage`.
- Duplicating a helper into a second feature instead of lifting it into Core
  is a finding — name both copies.
- Test doubles go in `SharedTestSupport`, never in a production target.

## Project generation

`TMDB.xcodeproj` and `TMDB.xcworkspace` are Tuist build artifacts and are
git-ignored. Any diff that touches `project.pbxproj` is a finding: the change
belongs in `Project.swift` followed by `tuist generate`.

Adding a `.swift` file inside an existing source folder needs no manifest
change (targets use globs). A new package, target, or top-level source folder
does — check `Project.swift` was updated in the same diff.
