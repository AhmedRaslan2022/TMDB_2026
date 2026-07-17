//
//  HTTPMethod.swift
//  TMDB
//
//  Created by Ahmed Raslan on 15/07/2026.
//

/// HTTP methods used by the TMDB API.
public enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}
