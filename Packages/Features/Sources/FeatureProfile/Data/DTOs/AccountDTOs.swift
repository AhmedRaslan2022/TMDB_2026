//
//  AccountDTOs.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

/// Wire shapes of TMDB's account responses. Internal to the Data layer.
/// camelCase because the shared decoder converts from snake_case.
struct AccountDTO: Decodable {
    let id: Int
    let username: String
    let name: String?
    let avatar: AvatarDTO?
}

struct AvatarDTO: Decodable {
    let tmdb: TMDBAvatarDTO?
    let gravatar: GravatarDTO?
}

struct TMDBAvatarDTO: Decodable {
    let avatarPath: String?
}

struct GravatarDTO: Decodable {
    let hash: String?
}

/// The favorites/watchlist list response, read only for its count.
struct CountDTO: Decodable {
    let totalResults: Int
}
