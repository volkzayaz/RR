//
//  TrackState.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 6/28/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct TrackState: Codable {

    let hash: String
    let progress: Float
    let isPlaying: Bool

    enum CodingKeys: String, CodingKey {
        case hash
        case progress
        case isPlaying
    }
}
