//
//  PersonViewModel.swift
//  TMDB
//
//  Created by Ahmed Raslan on 21/07/2026.
//

import CoreModels
import CoreUI
import Foundation
import Observation

/// Drives the person details screen: one bundle fetch plus the URL/label
/// composition the view needs.
@Observable
@MainActor
public final class PersonViewModel {
    public enum ViewState: Equatable {
        case idle
        case loading
        case loaded(PersonDetailsBundle)
        case error(LocalizedStringResource)
    }

    public private(set) var state: ViewState = .idle

    public let personID: Int
    private let fetchDetails: any FetchPersonDetailsUseCase
    private let imageBaseURL: URL

    public init(personID: Int, fetchDetails: any FetchPersonDetailsUseCase, imageBaseURL: URL) {
        self.personID = personID
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
            let bundle = try await fetchDetails.execute(personID: personID)
            state = .loaded(bundle)
        } catch is CancellationError {
            state = .idle
        } catch {
            state = .error(LocalizedStringResource(
                "person.error",
                defaultValue: "Couldn't load this person.",
                comment: "Shown when the person details fetch fails"
            ))
        }
    }

    /// The w185 headshot for the header.
    public func headshotURL(for person: Person) -> URL? {
        TMDBImageURL.url(base: imageBaseURL, path: person.profilePath, size: .w185)
    }

    /// The w342 poster for a filmography card.
    public func posterURL(for credit: PersonCredit) -> URL? {
        TMDBImageURL.url(base: imageBaseURL, path: credit.media.posterPath, size: .w342)
    }

    /// "Born December 18, 1963 · Shawnee, Oklahoma, USA", collapsing missing
    /// parts. Empty when nothing is known.
    public func birthLine(for person: Person) -> String {
        var parts: [String] = []
        if let birthday = person.birthday {
            parts.append(Self.dateFormatter.string(from: birthday))
        }
        if let place = person.placeOfBirth, !place.isEmpty {
            parts.append(place)
        }
        return parts.joined(separator: " · ")
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()
}
