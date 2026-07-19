//
//  UITestStubs.swift
//  TMDB
//
//  Created by Ahmed Raslan on 18/07/2026.
//

#if DEBUG
    import CoreModels
    import FeatureHome
    import FeatureMovieDetails
    import FeatureSearch
    import Foundation

    /// DEBUG-only seams for UI tests, which must run without network or real
    /// auth. Activated by the `-uitest-stubs` launch argument.
    enum UITestStubs {
        static var isActive: Bool {
            ProcessInfo.processInfo.arguments.contains("-uitest-stubs")
        }
    }

    /// Deterministic offline details bundle matching the stub list movies.
    struct StubFetchMovieDetailsUseCase: FetchMovieDetailsUseCase {
        func execute(movieID: Int) async throws -> MovieDetailsBundle {
            MovieDetailsBundle(
                details: MovieDetails(
                    id: movieID,
                    title: "UITest Movie \(movieID)",
                    overview: "Offline stub overview.",
                    voteAverage: 8.0,
                    voteCount: 42
                )
            )
        }
    }

    /// Deterministic offline search results, addressable by "search.movie.700".
    struct StubSearchMoviesUseCase: SearchMoviesUseCase {
        func execute(query: String, page: Int) async throws -> MoviePage {
            let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return MoviePage(page: 1, movies: [], totalPages: 1) }
            return MoviePage(
                page: page,
                movies: (700 ... 704).map {
                    Movie(id: $0, title: "Result \($0) for \(trimmed)", overview: "", voteAverage: 7, voteCount: 10)
                },
                totalPages: 1
            )
        }
    }

    /// In-memory recents so UI tests don't touch the on-disk store.
    @MainActor
    final class StubRecentSearchesRepository: RecentSearchesRepository {
        private var queries: [String] = []

        func recent(limit: Int) async throws -> [String] {
            Array(queries.prefix(max(0, limit)))
        }

        func record(_ query: String) async throws {
            queries.removeAll { $0 == query }
            queries.insert(query, at: 0)
        }

        func delete(_ query: String) async throws {
            queries.removeAll { $0 == query }
        }

        func clear() async throws {
            queries.removeAll()
        }
    }

    /// Deterministic offline movie lists. IDs start at 550 so UI tests can
    /// address "UITest Movie 550" and assert its details route.
    struct StubFetchMovieListUseCase: FetchMovieListUseCase {
        func execute(list _: MovieList, page: Int) async throws -> MoviePage {
            MoviePage(
                page: page,
                movies: (550 ... 559).map {
                    // posterPath stays nil: AsyncImage must not hit the
                    // network during UI tests.
                    Movie(id: $0, title: "UITest Movie \($0)", overview: "", voteAverage: 8.0, voteCount: 42)
                },
                totalPages: 1
            )
        }
    }
#endif
