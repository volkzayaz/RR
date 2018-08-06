//
//  PlayListItem.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 6/28/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct PlayerPlaylistItem: Codable {

    let id: Int
    let trackKey: String
    var nextTrackKey: String?
    var previousTrackKey: String?

    enum CodingKeys: String, CodingKey {
        case id
        case trackKey
        case nextTrackKey
        case previousTrackKey
    }

    init(id: Int, trackKey: String) {
        self.id = id
        self.trackKey = trackKey
    }

}
