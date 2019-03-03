//
//  PageTrackState.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 11/28/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct PageTrackState: Codable {

    let trackId: Int
    let isPlaying: Bool

    enum CodingKeys: String, CodingKey {
        case trackId = "id"
        case isPlaying
    }

    init(trackId: Int, isPlaying: Bool) {
        self.trackId = trackId
        self.isPlaying = isPlaying
    }
}
