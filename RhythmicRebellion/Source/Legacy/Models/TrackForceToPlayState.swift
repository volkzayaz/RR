//
//  ForceToPlay.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 9/25/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct TrackForceToPlayState: Codable {
    let trackId: Int
    let isForcedToPlay: Bool

    enum CodingKeys: String, CodingKey {
        case trackId = "id"
        case isForcedToPlay = "state"
    }
}
