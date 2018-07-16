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

    enum CodingKeys: String, CodingKey {
        case id
        case key
    }
}

extension TrackId: Equatable {
    static func == (lhs: TrackId, rhs: TrackId) -> Bool {
        return lhs.id == rhs.id
    }
}
