//
//  PersonCredit.swift
//  TMDB
//
//  Created by Ahmed Raslan on 21/07/2026.
//

import CoreModels

/// One filmography entry: a title the person worked on (as the shared
/// `MediaItem`, movie or TV) plus the character they played. Reusing
/// `MediaItem` is what lets a person's mixed movie/TV credits render in the
/// same grid and navigate onward to those titles.
public struct PersonCredit: Identifiable, Hashable, Sendable {
    /// Identity is the underlying title (kind + id); the mapper de-dupes
    /// repeated credits on the same title down to one entry.
    public var id: String {
        "\(media.mediaType.rawValue).\(media.id)"
    }

    public let media: MediaItem
    /// The role played, when TMDB provides one.
    public let character: String?

    public init(media: MediaItem, character: String? = nil) {
        self.media = media
        self.character = character
    }
}

/// The full person detail payload: bio + filmography + headshot gallery.
public struct PersonDetailsBundle: Hashable, Sendable {
    public let person: Person
    /// Acting credits, most-notable first (by TMDB vote count).
    public let filmography: [PersonCredit]
    /// TMDB image paths for the person's profile gallery.
    public let imagePaths: [String]

    public init(person: Person, filmography: [PersonCredit] = [], imagePaths: [String] = []) {
        self.person = person
        self.filmography = filmography
        self.imagePaths = imagePaths
    }
}
