//
//  UITestStubs.swift
//  TMDB
//
//  Created by Ahmed Raslan on 18/07/2026.
//

#if DEBUG
    import CoreModels
    import FeatureFavorites
    import FeatureHome
    import FeatureMovieDetails
    import FeatureProfile
    import FeatureSearch
    import Foundation

    /// DEBUG-only seams for UI tests, which must run without network or real
    /// auth. Activated by the `-uitest-stubs` launch argument.
    enum UITestStubs {
        static var isActive: Bool {
            ProcessInfo.processInfo.arguments.contains("-uitest-stubs")
        }
    }

    /// Shared in-memory favorites store for UI tests, so a favorite toggled on
    /// the details screen appears on the Favorites tab (same instance both
    /// places). No SwiftData, no network.
    @MainActor
    final class StubFavoritesRepository: FavoritesRepository {
        static let shared = StubFavoritesRepository()
        private var movies: [Movie] = []

        func favorites() async throws -> [Movie] {
            movies
        }

        func isFavorite(movieID: Int) async throws -> Bool {
            movies.contains { $0.id == movieID }
        }

        func setFavorite(_ movie: Movie, isFavorite: Bool) async throws {
            movies.removeAll { $0.id == movie.id }
            if isFavorite {
                movies.insert(movie, at: 0)
            }
        }

        func synchronize() async throws {}
    }

    /// Details-screen favorite toggle backed by the shared favorites store.
    @MainActor
    struct StubFavoriteToggling: FavoriteToggling {
        func isFavorite(movieID: Int) async -> Bool {
            await (try? StubFavoritesRepository.shared.isFavorite(movieID: movieID)) ?? false
        }

        func setFavorite(_ movie: Movie, isFavorite: Bool) async throws {
            try await StubFavoritesRepository.shared.setFavorite(movie, isFavorite: isFavorite)
        }
    }

    /// In-memory watchlist toggle for UI tests.
    @MainActor
    final class StubWatchlistToggling: WatchlistToggling {
        private var onWatchlist: Set<Int> = []
        func isOnWatchlist(movieID: Int) async -> Bool {
            onWatchlist.contains(movieID)
        }

        func setOnWatchlist(_ movie: Movie, isOnWatchlist: Bool) async throws {
            if isOnWatchlist {
                onWatchlist.insert(movie.id)
            } else {
                onWatchlist.remove(movie.id)
            }
        }
    }

    /// In-memory rating store for UI tests — accepts writes and reflects them.
    @MainActor
    final class StubMovieRatingRepository: MovieRatingRepository {
        private var ratings: [Int: Double] = [:]

        func rating(movieID: Int) async throws -> Double? {
            ratings[movieID]
        }

        func setRating(_ value: Double?, movieID: Int) async throws {
            ratings[movieID] = value
        }
    }

    /// Deterministic offline account for the Profile tab.
    struct StubProfileRepository: ProfileRepository {
        func account() async throws -> Account {
            Account(id: 1, username: "uitester", name: "UI Tester", gravatarHash: "hash")
        }

        func stats(for _: Int) async throws -> AccountStats {
            AccountStats(favoriteCount: 3, watchlistCount: 2)
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

    /// Deterministic offline Discover results, addressable by
    /// "discover.movie.900". Reflects the genre filter so a UI test can prove a
    /// toggle changes the result set.
    struct StubDiscoverMoviesUseCase: DiscoverMoviesUseCase {
        func genres() async throws -> [MovieGenre] {
            [MovieGenre(id: 28, name: "Action"), MovieGenre(id: 35, name: "Comedy")]
        }

        func execute(filters: DiscoverFilters, page: Int) async throws -> MoviePage {
            // A selected genre shifts the ID base so the grid visibly changes.
            let base = 900 + (filters.genreIDs.first ?? 0)
            return MoviePage(
                page: page,
                movies: (base ... base + 4).map {
                    Movie(id: $0, title: "Discover \($0)", overview: "", voteAverage: 7, voteCount: 500)
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
