//
//  City.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 9/5/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct City: Codable {

    let id: Int
    let name: String
    let countryCode: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case countryCode = "country_code"
    }

}

extension City: Hashable {

    static func == (lhs: City, rhs: City) -> Bool {
        return lhs.id == rhs.id && lhs.countryCode == rhs.countryCode
    }

}
