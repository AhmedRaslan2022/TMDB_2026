//
//  AuthDTOs.swift
//  TMDB
//
//  Created by Ahmed Raslan on 17/07/2026.
//

/// Wire shapes of TMDB's authentication responses. Internal to the Data
/// layer — they never cross into Domain or out of the module. Property names
/// are camelCase because the shared decoder converts from snake_case.
struct RequestTokenDTO: Decodable {
    let success: Bool
    let expiresAt: String
    let requestToken: String
}

struct CreateSessionDTO: Decodable {
    let success: Bool
    let sessionId: String
}

struct GuestSessionDTO: Decodable {
    let success: Bool
    let guestSessionId: String
    let expiresAt: String
}
