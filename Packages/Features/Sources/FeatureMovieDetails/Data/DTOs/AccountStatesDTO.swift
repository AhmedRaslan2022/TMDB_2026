//
//  AccountStatesDTO.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

/// TMDB's `/account_states` payload. Internal to the Data layer.
///
/// The `rated` field is heterogeneous: `false` when the user hasn't rated the
/// movie, or `{ "value": Double }` when they have — decoded here into an
/// optional `Double`.
struct AccountStatesDTO: Decodable {
    let ratingValue: Double?

    private enum CodingKeys: String, CodingKey {
        case rated
    }

    private struct RatedObject: Decodable {
        let value: Double
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // `false` ⇒ unrated; an object ⇒ the rating. Absent ⇒ unrated too.
        if let object = try? container.decode(RatedObject.self, forKey: .rated) {
            ratingValue = object.value
        } else {
            ratingValue = nil
        }
    }
}
