//
//  FanPlaylistState.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 11/1/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct FanPlaylistState: Codable {

    let id: Int
    let playlist: FanPlaylist?

    enum CodingKeys: String, CodingKey {
        case id
        case playlist = "value"
    }

    init(id: Int, playlist: FanPlaylist?) {
        self.id = id
        self.playlist = playlist
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.playlist = try container.decodeIfPresent(FanPlaylist.self, forKey: .playlist)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(self.id, forKey: .id)
        if let playlist = playlist {
            try container.encode(playlist, forKey: .playlist)
        } else {
            try container.encodeNil(forKey: .playlist)
        }

    }
}
