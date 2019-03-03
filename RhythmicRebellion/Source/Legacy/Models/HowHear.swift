//
//  HowHear.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 9/6/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct HowHear: Codable {

    let id: Int
    let name: String

    enum CodingKeys: String, CodingKey {
        case id
        case name = "label"
    }

}

extension HowHear: Equatable {
    static func == (lhs: HowHear, rhs: HowHear) -> Bool {
        return lhs.id == rhs.id
    }
}

extension HowHear: Hashable {
    public var hashValue: Int { return self.id }
}
