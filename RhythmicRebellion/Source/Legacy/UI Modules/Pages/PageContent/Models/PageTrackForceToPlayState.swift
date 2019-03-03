//
//  PageTrackForceToPlayState.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 11/29/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct PageTrackForceToPlayState: Codable {
    let trackId: Int
    let isForcedToPlay: Bool

    enum CodingKeys: String, CodingKey {
        case trackId
        case isForcedToPlay = "force"
    }
}
