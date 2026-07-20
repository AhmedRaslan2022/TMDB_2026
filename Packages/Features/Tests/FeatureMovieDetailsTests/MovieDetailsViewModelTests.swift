//
//  MovieDetailsViewModelTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 19/07/2026.
//

import CoreModels
import Foundation
import Testing
@testable import FeatureMovieDetails

@MainActor
@Suite("MovieDetailsViewModel")
struct MovieDetailsViewModelTests {
    private enum MockError: Error {
        case stubbed
    }

    @MainActor
    private final class FetchDetailsMock: FetchMovieDetailsUseCase {
        var result: Result<MovieDetailsBundle, Error> = .failure(MockError.stubbed)
        private(set) var requestedIDs: [Int] = []

        func execute(movieID: Int) async throws -> MovieDetailsBundle {
            requestedIDs.append(movieID)
            return try result.get()
        }
    }

    private let useCase = FetchDetailsMock()
    private let favorites = FavoriteTogglingMock()
    private let watchlistMock = WatchlistTogglingMock()
    private let ratingMock = MovieRatingRepositoryMock()
    private let viewModel: MovieDetailsViewModel

    init() throws {
        viewModel = try MovieDetailsViewModel(
            movieID: 550,
            fetchDetails: useCase,
            favorites: favorites,
            watchlist: watchlistMock,
            rating: ratingMock,
            imageBaseURL: #require(URL(string: "https://img.invalid/t/p"))
        )
    }

    private func bundle(videos: [MovieVideo] = []) -> MovieDetailsBundle {
        MovieDetailsBundle(
            details: MovieDetails(id: 550, title: "Fight Club", overview: "…", backdropPath: "/backdrop.jpg"),
            videos: videos
        )
    }

    @Test("load requests the screen's movie and lands in loaded")
    func loadSuccess() async {
        useCase.result = .success(bundle())

        await viewModel.load()

        #expect(viewModel.state == .loaded(bundle()))
        #expect(useCase.requestedIDs == [550])
    }

    @Test("load is idempotent once loaded — a re-appearing view refetches nothing")
    func loadIdempotent() async {
        useCase.result = .success(bundle())
        await viewModel.load()

        await viewModel.load()

        #expect(useCase.requestedIDs == [550])
    }

    @Test("failure lands in error; load retries out of it")
    func failureAndRetry() async {
        await viewModel.load()

        guard case .error = viewModel.state else {
            Issue.record("expected .error, got \(viewModel.state)")
            return
        }

        useCase.result = .success(bundle())
        await viewModel.load()
        #expect(viewModel.state == .loaded(bundle()))
    }

    @Test("cancellation returns to idle, not error")
    func cancellation() async {
        useCase.result = .failure(CancellationError())

        await viewModel.load()

        #expect(viewModel.state == .idle)
    }

    @Test("backdrop URL uses w780, falling back to the poster path")
    func backdropURL() {
        let withBackdrop = MovieDetails(id: 1, title: "A", overview: "", backdropPath: "/b.jpg")
        let posterOnly = MovieDetails(id: 2, title: "B", overview: "", posterPath: "/p.jpg")

        #expect(viewModel.backdropURL(for: withBackdrop)?.absoluteString == "https://img.invalid/t/p/w780/b.jpg")
        #expect(viewModel.backdropURL(for: posterOnly)?.absoluteString == "https://img.invalid/t/p/w780/p.jpg")
        #expect(viewModel.backdropURL(for: MovieDetails(id: 3, title: "C", overview: "")) == nil)
    }

    @Test("profile and poster URLs use their size buckets")
    func imageURLSizes() {
        let member = CastMember(id: "c1", personID: 1, name: "A", profilePath: "/face.jpg")
        let movie = Movie(id: 1, title: "A", overview: "", posterPath: "/poster.jpg")

        #expect(viewModel.profileURL(for: member)?.absoluteString == "https://img.invalid/t/p/w185/face.jpg")
        #expect(viewModel.posterURL(for: movie)?.absoluteString == "https://img.invalid/t/p/w342/poster.jpg")
        #expect(viewModel.profileURL(for: CastMember(id: "c2", personID: 2, name: "B")) == nil)
    }

    @Test("watch and thumbnail URLs are site-aware")
    func videoURLs() {
        let youTube = MovieVideo(id: "v1", name: "T", key: "abc", site: .youTube, type: "Trailer")
        let vimeo = MovieVideo(id: "v2", name: "T", key: "123", site: .vimeo, type: "Trailer")

        #expect(viewModel.watchURL(for: youTube)?.absoluteString == "https://www.youtube.com/watch?v=abc")
        #expect(viewModel.watchURL(for: vimeo)?.absoluteString == "https://vimeo.com/123")
        #expect(viewModel.thumbnailURL(for: youTube)?.absoluteString == "https://img.youtube.com/vi/abc/hqdefault.jpg")
        #expect(viewModel.thumbnailURL(for: vimeo) == nil)
    }

    @Test("featured videos: official trailers first; teasers only when no trailers exist")
    func featuredVideoOrdering() {
        let unofficialTrailer = MovieVideo(id: "v1", name: "Fan cut", key: "a", site: .youTube, type: "Trailer")
        let officialTrailer = MovieVideo(id: "v2", name: "Official", key: "b", site: .youTube, type: "Trailer", isOfficial: true)
        let teaser = MovieVideo(id: "v3", name: "Teaser", key: "c", site: .youTube, type: "Teaser")

        let withTrailers = viewModel.featuredVideos(in: bundle(videos: [teaser, unofficialTrailer, officialTrailer]))
        #expect(withTrailers.map(\.id) == ["v2", "v1"], "official first, teaser excluded")

        let teasersOnly = viewModel.featuredVideos(in: bundle(videos: [teaser]))
        #expect(teasersOnly.map(\.id) == ["v3"])
    }
}
