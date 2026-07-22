//
//  Person.swift
//  TMDB
//
//  Created by Ahmed Raslan on 21/07/2026.
//

import Foundation

/// An actor or crew member as the domain sees it.
public struct Person: Identifiable, Hashable, Sendable {
    public let id: Int
    public let name: String
    public let biography: String
    public let birthday: Date?
    public let deathday: Date?
    public let placeOfBirth: String?
    /// TMDB image path for the headshot; resolved by the presentation layer.
    public let profilePath: String?
    /// e.g. "Acting", "Directing" — TMDB's `known_for_department`.
    public let knownForDepartment: String?

    public init(
        id: Int,
        name: String,
        biography: String,
        birthday: Date? = nil,
        deathday: Date? = nil,
        placeOfBirth: String? = nil,
        profilePath: String? = nil,
        knownForDepartment: String? = nil
    ) {
        self.id = id
        self.name = name
        self.biography = biography
        self.birthday = birthday
        self.deathday = deathday
        self.placeOfBirth = placeOfBirth
        self.profilePath = profilePath
        self.knownForDepartment = knownForDepartment
    }
}
