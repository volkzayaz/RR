//
//  CityInfo.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 9/5/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct CityInfo: Codable {

    let id: Int
    let name: String
    let countryCode: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case countryCode = "country_code"
    }

}

extension CityInfo: Hashable {

    static func == (lhs: CityInfo, rhs: CityInfo) -> Bool {
        return lhs.id == rhs.id && lhs.countryCode == rhs.countryCode
    }

}
