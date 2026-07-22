//
//  PersonEndpoint.swift
//  TMDB
//
//  Created by Ahmed Raslan on 21/07/2026.
//

import Foundation
import Networking

/// `GET /person/{id}` with `append_to_response`, so bio, combined (movie + TV)
/// credits, and the image gallery arrive in one request.
struct PersonEndpoint: Endpoint {
    let personID: Int

    var path: String {
        "/person/\(personID)"
    }

    var queryItems: [URLQueryItem] {
        [URLQueryItem(name: "append_to_response", value: "combined_credits,images")]
    }
}
