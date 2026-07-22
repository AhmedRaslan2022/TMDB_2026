//
//  JSONDecoder+TMDB.swift
//  TMDB
//
//  Created by Ahmed Raslan on 22/07/2026.
//

import Foundation

extension JSONDecoder {
    /// The single decoder configuration for the Networking layer, so every
    /// client — and the `LoggingAPIClient` decorator, which decodes typed
    /// responses itself to log their bodies — decodes TMDB's snake_case JSON
    /// identically. Sharing one factory means the two can never drift apart.
    ///
    /// Returns a fresh instance each time; `JSONDecoder` is a reference type.
    static var tmdb: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
}
