//
//  MovieDetailsBundle.swift
//  TMDB
//
//  Created by Ahmed Raslan on 19/07/2026.
//

import CoreModels

/// Everything the details screen needs, fetched as one unit — the data layer
/// uses TMDB's `append_to_response` so this costs a single request.
public struct MovieDetailsBundle: Hashable, Sendable {
    public let details: MovieDetails
    /// Cast in billing order.
    public let cast: [CastMember]
    public let videos: [MovieVideo]
    public let similar: [Movie]
    public let recommendations: [Movie]

    public init(
        details: MovieDetails,
        cast: [CastMember] = [],
        videos: [MovieVideo] = [],
        similar: [Movie] = [],
        recommendations: [Movie] = []
    ) {
        self.details = details
        self.cast = cast
        self.videos = videos
        self.similar = similar
        self.recommendations = recommendations
    }
}
