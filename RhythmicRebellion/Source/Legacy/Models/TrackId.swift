//
//  TrackId.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 6/28/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct TrackId: Codable {
    let id: Int
    let key: String
    let skipStat: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case key
        case skipStat
    }

    init(id: Int, key: String, skipStat: Bool? = nil) {
        self.id = id
        self.key = key
        self.skipStat = skipStat
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.key = try container.decode(String.self, forKey: .key)

        self.skipStat = nil
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(self.id, forKey: .id)
        try container.encode(self.key, forKey: .key)

        if let skipStat = self.skipStat, skipStat == true {
            try container.encode(skipStat, forKey: .skipStat)
        }
    }
}

extension TrackId: Equatable {
    static func == (lhs: TrackId, rhs: TrackId) -> Bool {
        return lhs.id == rhs.id
    }
}
