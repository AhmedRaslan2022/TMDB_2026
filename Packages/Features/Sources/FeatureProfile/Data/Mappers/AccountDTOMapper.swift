//
//  AccountDTOMapper.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

extension AccountDTO {
    func toDomain() -> Account {
        Account(
            id: id,
            username: username,
            // TMDB returns "" for an unset display name — normalize to nil.
            name: name.flatMap { $0.isEmpty ? nil : $0 },
            avatarPath: avatar?.tmdb?.avatarPath.flatMap { $0.isEmpty ? nil : $0 },
            gravatarHash: avatar?.gravatar?.hash.flatMap { $0.isEmpty ? nil : $0 }
        )
    }
}
