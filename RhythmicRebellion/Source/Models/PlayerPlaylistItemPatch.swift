//
//  PlayListItem.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 6/28/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct PlayerPlaylistItemPatch: Codable {
    
    typealias KeyType = OptionalValue<String>
    
    let trackId: Int?
    let key: String?
    var nextKey: KeyType?
    var previousKey: KeyType?
    
    enum CodingKeys: String, CodingKey {
        case trackId = "id"
        case key = "trackKey"
        case nextKey = "nextTrackKey"
        case previousKey = "previousTrackKey"
    }
    
    init(trackId: Int? = nil, key: String? = nil, nextKey: KeyType? = nil, previousKey: KeyType? = nil) {
        self.trackId = trackId
        self.key = key
        
        self.nextKey = nextKey
        self.previousKey = previousKey
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.trackId = try container.decodeIfPresent(Int.self, forKey: .trackId)
        self.key = try container.decodeIfPresent(String.self, forKey: .key)
        
        self.nextKey = try container.decodeIfPresent(KeyType.self, forKey: .nextKey)
        self.previousKey = try container.decodeIfPresent(KeyType.self, forKey: .previousKey)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        if let trackId = self.trackId { try container.encode(trackId, forKey: .trackId) }
        if let key = self.key { try container.encode(key, forKey: .key) }
        if let nextKey = self.nextKey { try container.encode(nextKey, forKey: .nextKey) }
        if let previousKey = previousKey { try container.encode(previousKey, forKey: .previousKey) }
    }
}
