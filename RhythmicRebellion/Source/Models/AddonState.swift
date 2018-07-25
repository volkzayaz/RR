//
//  AddonState.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/11/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct AddonState: Codable {

    let id: Int
    let typeValue: Int
    let trackId: Int

    var type: AddonType { return AddonType(rawValue: typeValue) ?? .unknown}

    enum CodingKeys: String, CodingKey {
        case id
        case typeValue = "type"
        case trackId = "srtId"
    }

    public init(id: Int, typeValue: Int, trackId: Int) {
        self.id = id
        self.typeValue = typeValue
        self.trackId = trackId
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.typeValue = try container.decode(Int.self, forKey: .typeValue)
        self.trackId = try container.decode(Int.self, forKey: .trackId)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(self.id, forKey: .id)
        try container.encode(self.typeValue, forKey: .typeValue)
        try container.encode(self.trackId, forKey: .trackId)
    }

}
