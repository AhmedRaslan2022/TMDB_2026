# SwiftUI review

## Modern API

Flag deprecated spellings — they read as dated code in a portfolio review.

| Deprecated | Use |
| --- | --- |
| `foregroundColor(_:)` | `foregroundStyle(_:)` |
| `NavigationView` | `NavigationStack` / `NavigationSplitView` |
| `NavigationLink(destination:)` | value-based `NavigationLink(value:)` + `navigationDestination(for:)` |
| `.onChange(of:) { newValue in }` | two-parameter or zero-parameter form (iOS 17) |
| `.animation(_:)` (implicit) | `.animation(_:value:)` |
| `cornerRadius(_:)` | `.clipShape(.rect(cornerRadius:))` |
| `UIScreen.main.bounds` | `GeometryReader` / `containerRelativeFrame` |
| `.accentColor` | `.tint` |

## View composition

- A `body` deeper than ~3 nesting levels or longer than a screen is a finding:
  extract a subview (a `struct`, not a `@ViewBuilder var` that keeps the same
  observation scope).
- Files over ~300 lines get decomposed. One type per file.
- Extract subviews that take **values**, not the whole ViewModel — passing the
  ViewModel down makes the child observe everything it owns.
- No business logic in a view: no filtering, sorting, formatting decisions,
  or error interpretation. Those belong in the ViewModel or a use case.

```swift
// Before — logic in the body
List(viewModel.movies.filter { $0.rating > minimum }.sorted(by: ...)) { ... }

// After
List(viewModel.visibleMovies) { ... }   // computed once in the ViewModel
```

## State and bindings

```swift
// Before — a manual binding that fires on every render
TextField("Search", text: Binding(
    get: { viewModel.query },
    set: { viewModel.query = $0; viewModel.search() }
))

// After
TextField("Search", text: $viewModel.query)
    .onChange(of: viewModel.query) { viewModel.search() }
```

- `Binding(get:set:)` inside a `body` is almost always a finding.
- `@Bindable var viewModel` is what makes `$viewModel.query` legal with
  `@Observable` — check it is present rather than `@State` on a passed-in
  object.

## Lists and identity

- `ForEach(items, id: \.self)` on a non-`Hashable`-stable type causes wrong
  animations and lost state. Use `Identifiable` with a real stable id.
- Array indices as identity (`ForEach(0..<items.count)`) break on insertion
  and crash on concurrent mutation.
- `.id()` on a view forces a full teardown — legitimate to reset state,
  a performance bug when applied inside a `ForEach` body.

## Performance

- Work in `body` runs on every render: no `DateFormatter()` construction,
  no sorting, no image decoding. Hoist to the ViewModel or a cached value.
- `GeometryReader` greedily takes all available space — a common cause of
  layouts that "collapse". Prefer `containerRelativeFrame` or
  `onGeometryChange` where possible.
- `AnyView` erases the type and defeats structural diffing. Use `@ViewBuilder`
  or a `Group` with branches instead.
- Images: the actor-based cache in `CoreUI`/`Networking` is the only image
  loader. Flag any ad-hoc `URLSession` image fetch in a view.

## Accessibility

Non-negotiable in a portfolio app, and cheap to get right:

```swift
// Before — invisible to VoiceOver
Button(action: addFavorite) { Image(systemName: "heart") }

// After
Button("Add to favorites", systemImage: "heart", action: addFavorite)
```

- Icon-only controls need a label.
- Decorative images need `.accessibilityHidden(true)`; meaningful ones need a
  description.
- Fixed `.frame(height:)` on text containers clips at large Dynamic Type.
  Test at AX5 mentally: does the layout wrap or truncate?
- Composite rows should use `.accessibilityElement(children: .combine)` so
  VoiceOver reads one item, not five fragments.
- Animations must respect `@Environment(\.accessibilityReduceMotion)`.
- Colour alone must never carry meaning (rating, availability, status).

## Strings

User-facing text goes through String Catalogs from day one. A hardcoded
`Text("No results")` is a finding — it becomes localization debt that Sprint 8
has to pay off. `Text(verbatim:)` is correct for non-localizable content
(numbers, names) and should be used deliberately.
