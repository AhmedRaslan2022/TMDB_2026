//
//  UITestStubs.swift
//  TMDB
//
//  Created by Ahmed Raslan on 18/07/2026.
//

#if DEBUG
    import CoreModels
    import FeatureHome
    import Foundation

    /// DEBUG-only seams for UI tests, which must run without network or real
    /// auth. Activated by the `-uitest-stubs` launch argument.
    enum UITestStubs {
        static var isActive: Bool {
            ProcessInfo.processInfo.arguments.contains("-uitest-stubs")
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
