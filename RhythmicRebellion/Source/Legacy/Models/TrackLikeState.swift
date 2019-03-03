//
//  TrackLikeState.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 11/2/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct TrackLikeState: Codable {

    let id: Int
    let state: Track.LikeStates

    enum CodingKeys: String, CodingKey {
        case id
        case state
    }

    init(id: Int, state: Track.LikeStates) {
        self.id = id
        self.state = state
    }
}
