//
//  PlayListItem.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 6/28/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct PlayerPlaylistItemPatch: Codable {
    
    let trackId: Int?
    let key: String?
    let nextKey: String??
    let previousKey: String??

    enum CodingKeys: String, CodingKey {
        case trackId = "id"
        case key = "trackKey"
        case nextKey = "nextTrackKey"
        case previousKey = "previousTrackKey"
    }

    init(trackId: Int? = nil, key: String? = nil, nextKey: String? = nil, previousKey: String? = nil) {
        self.trackId = trackId
        self.key = key

        self.nextKey = nextKey
        self.previousKey = previousKey
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.trackId = try container.decodeIfPresent(Int.self, forKey: .trackId)
        self.key = try container.decodeIfPresent(String.self, forKey: .key)

        if let nextKey = try container.decodeIfPresent(Optional<String>.self, forKey: .nextKey),
           let x = nextKey {
            self.nextKey = x ///value equals to string
        } else if try container.decodeNil(forKey: .nextKey)  {
            self.nextKey = nil as String? ///value equals to null
        } else {
            self.nextKey = nil as String?? ///value is absent
        }

        
        if let previousKey = try container.decodeIfPresent(Optional<String>.self, forKey: .previousKey),
            let x = previousKey {
            self.previousKey = x
        } else if container.contains(.previousKey) {
            self.previousKey = nil as String? ///value equals to null
        } else {
            self.previousKey = nil as String?? ///value is absent
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        if let trackId = self.trackId { try container.encode(trackId, forKey: .trackId) }
        if let key = self.key { try container.encode(key, forKey: .key) }
        if let nextKey = self.nextKey { try container.encode(nextKey, forKey: .nextKey) }
        if let previousKey = previousKey { try container.encode(previousKey, forKey: .previousKey) }
    }    
}
