//
//  State.swift
//  RhythmicRebellion
//
//  Created by Soroka Vlad on 9/4/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct Region: Codable {

    let id: Int
    let name: String
    let country_code: String

}

extension Region: Hashable {

    static func == (lhs: Region, rhs: Region) -> Bool {
        return lhs.id == rhs.id && lhs.country_code == rhs.country_code
    }

    public var hashValue: Int { return self.id }
}
