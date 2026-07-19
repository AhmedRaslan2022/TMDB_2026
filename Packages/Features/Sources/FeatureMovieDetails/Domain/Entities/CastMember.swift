//
//  CastMember.swift
//  TMDB
//
//  Created by Ahmed Raslan on 19/07/2026.
//

/// One cast credit, in billing order.
public struct CastMember: Hashable, Sendable, Identifiable {
    /// The credit ID (unique per role — an actor can hold several credits).
    public let id: String
    /// The person's TMDB ID, for navigation to person details (Sprint 6).
    public let personID: Int
    public let name: String
    public let character: String?
    public let profilePath: String?

    public init(id: String, personID: Int, name: String, character: String? = nil, profilePath: String? = nil) {
        self.id = id
        self.personID = personID
        self.name = name
        self.character = character
        self.profilePath = profilePath
    }
}
