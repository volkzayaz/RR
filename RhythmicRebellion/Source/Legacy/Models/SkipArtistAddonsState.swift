//
//  SkipArtistAddonsState.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 11/22/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct SkipArtistAddonsState: Codable {

    let artistId: String
    let isSkipped: Bool

    enum CodingKeys: String, CodingKey {
        case artistId = "id"
        case isSkipped = "state"
    }

    init(artistId: String, isSkipped: Bool) {
        self.artistId = artistId
        self.isSkipped = isSkipped
    }
}
