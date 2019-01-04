//
//  ArtistFollowingState.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 10/3/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct ArtistFollowingState: Codable, Hashable {
    let artistId: String
    let isFollowed: Bool

    enum CodingKeys: String, CodingKey {
        case artistId = "id"
        case isFollowed = "state"
    }
    
    public var hashValue: Int { return artistId.hashValue }
    
}
