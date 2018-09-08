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
    let regionId: Int
    let regionCode: String

    enum DecodingKeys: String, CodingKey {
        case id
        case name
        case countryCode = "country_code"
        case regionId = "state_id"
        case regionCode = "admin1_code"
    }

    enum EncodingKeys: String, CodingKey {
        case id
        case name
        case countryCode = "countryCode"
        case regionId = "stateId"
        case regionCode = "stateCode"
    }

    public init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: DecodingKeys.self)

        self.id = try container.decode(Int.self, forKey: DecodingKeys.id)
        self.name = try container.decode(String.self, forKey: DecodingKeys.name)

        self.countryCode = try container.decode(String.self, forKey: DecodingKeys.countryCode)
        self.regionId = try container.decode(Int.self, forKey: DecodingKeys.regionId)
        self.regionCode = try container.decode(String.self, forKey: DecodingKeys.regionCode)
    }


    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: EncodingKeys.self)

        try container.encode(self.id, forKey: EncodingKeys.id)
        try container.encode(self.name, forKey: EncodingKeys.name)

        try container.encode(self.countryCode, forKey: EncodingKeys.countryCode)
        try container.encode(self.regionCode, forKey: EncodingKeys.regionCode)
    }
}

extension City: Equatable {
    static func == (lhs: City, rhs: City) -> Bool {
        return lhs.id == rhs.id && lhs.countryCode == rhs.countryCode && lhs.regionId == rhs.regionId
    }
}

extension City: Hashable {
    public var hashValue: Int { return self.id }
}
