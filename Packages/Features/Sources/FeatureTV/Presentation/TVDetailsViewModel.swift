//
//  TVDetailsViewModel.swift
//  TMDB
//
//  Created by Ahmed Raslan on 21/07/2026.
//

import CoreModels
import CoreUI
import Foundation
import Observation

/// Drives the TV details screen: one bundle fetch plus the URL/label
/// composition the view needs.
@Observable
@MainActor
public final class TVDetailsViewModel {
    public enum ViewState: Equatable {
        case idle
        case loading
        case loaded(TVShowDetailsBundle)
        case error(LocalizedStringResource)
    }

    public private(set) var state: ViewState = .idle

    public let showID: Int
    private let fetchDetails: any FetchTVDetailsUseCase
    private let imageBaseURL: URL

    public init(showID: Int, fetchDetails: any FetchTVDetailsUseCase, imageBaseURL: URL) {
        self.showID = showID
        self.fetchDetails = fetchDetails
        self.imageBaseURL = imageBaseURL
    }

    /// Loads the bundle. Idempotent once loaded; callable from error (retry).
    public func load() async {
        switch state {
        case .loading, .loaded: return
        case .idle, .error: break
        }
        state = .loading
        do {
            let bundle = try await fetchDetails.execute(showID: showID)
            state = .loaded(bundle)
        } catch is CancellationError {
            state = .idle
        } catch {
            state = .error(LocalizedStringResource(
                "tv.details.error",
                defaultValue: "Couldn't load this show.",
                comment: "Shown when the TV details fetch fails"
            ))
        }
    }

    /// The w780 backdrop for the header (poster as fallback).
    public func backdropURL(for details: TVShowDetails) -> URL? {
        TMDBImageURL.url(base: imageBaseURL, path: details.backdropPath ?? details.posterPath, size: .w780)
    }

    /// The w342 poster for similar-show cards.
    public func posterURL(for show: MediaItem) -> URL? {
        TMDBImageURL.url(base: imageBaseURL, path: show.posterPath, size: .w342)
    }

    /// A compact "2008 · 5 seasons · 62 episodes" style metadata line.
    public func metadata(for details: TVShowDetails) -> String {
        var parts: [String] = []
        if let date = details.firstAirDate {
            parts.append(String(Calendar(identifier: .gregorian).component(.year, from: date)))
        }
        if details.numberOfSeasons > 0 {
            parts.append("\(details.numberOfSeasons) season\(details.numberOfSeasons == 1 ? "" : "s")")
        }
        if details.numberOfEpisodes > 0 {
            parts.append("\(details.numberOfEpisodes) episode\(details.numberOfEpisodes == 1 ? "" : "s")")
        }
        return parts.joined(separator: " · ")
    }
}
