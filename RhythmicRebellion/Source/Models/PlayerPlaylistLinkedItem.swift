//
//  PlayListItem.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 6/28/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct PlayerPlaylistLinkedItem: Codable {

    let trackId: Int
    let key: String
    var nextKey: String?
    var previousKey: String?

    enum CodingKeys: String, CodingKey {
        case trackId = "id"
        case key = "trackKey"
        case nextKey = "nextTrackKey"
        case previousKey = "previousTrackKey"
    }

    init(trackId: Int, key: String) {
        self.trackId = trackId
        self.key = key
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(trackId, forKey: .trackId)
        try container.encode(key, forKey: .key)
        try container.encode(nextKey, forKey: .nextKey)
        try container.encode(previousKey, forKey: .previousKey)
    }    
}


extension PlayerPlaylistLinkedItem: Equatable {
    static func == (lhs: PlayerPlaylistLinkedItem, rhs: PlayerPlaylistLinkedItem) -> Bool {
        return lhs.key == rhs.key && lhs.trackId == rhs.trackId
    }
}
