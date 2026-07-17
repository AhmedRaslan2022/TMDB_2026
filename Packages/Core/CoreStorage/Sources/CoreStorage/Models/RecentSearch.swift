// By Ahmed Raslan ®

import Foundation
import SwiftData

/// A query the user searched for, kept for the recent-searches list.
@Model
public final class RecentSearch {
    /// The query text, unique — repeating a search refreshes `searchedAt`.
    @Attribute(.unique) public var query: String
    public var searchedAt: Date

    public init(query: String, searchedAt: Date = .now) {
        self.query = query
        self.searchedAt = searchedAt
    }
}
