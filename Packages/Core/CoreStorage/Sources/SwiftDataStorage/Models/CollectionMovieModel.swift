//
//  CollectionMovieModel.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

import Foundation
import SwiftData

/// Shared shape of a saved-movie collection entry (favorites, watchlist).
/// Lets one generic local data source persist any such collection instead of
/// duplicating the CRUD per model.
public protocol CollectionMovieModel: PersistentModel {
    var movieID: Int { get set }
    var title: String { get set }
    var posterPath: String? { get set }
    /// When the user added it locally — drives sort order.
    var addedAt: Date { get set }

    init(movieID: Int, title: String, posterPath: String?, addedAt: Date)
}
