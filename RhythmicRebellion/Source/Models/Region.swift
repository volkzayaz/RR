//
//  State.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 9/4/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct Region: Codable {

    let id: Int
    let code: String
    let name: String
    let countryId: Int
    let countryCode: String

    enum DecodingKeys: String, CodingKey {
        case id
        case code = "admin1_code"
        case name
        case countryId = "country_id"
        case countryCode = "country_code"
    }

    enum EncodingKeys: String, CodingKey {
        case id
        case code = "stateCode"
        case name
        case countryId = "countryId"
        case countryCode = "countryCode"
    }

    public init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: DecodingKeys.self)

        self.id = try container.decode(Int.self, forKey: DecodingKeys.id)
        self.code = try container.decode(String.self, forKey: DecodingKeys.code)
        self.name = try container.decode(String.self, forKey: DecodingKeys.name)

        self.countryId = try container.decode(Int.self, forKey: DecodingKeys.countryId)
        self.countryCode = try container.decode(String.self, forKey: DecodingKeys.countryCode)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: EncodingKeys.self)

        try container.encode(self.id, forKey: EncodingKeys.id)
        try container.encode(self.code, forKey: EncodingKeys.code)
        try container.encode(self.name, forKey: EncodingKeys.name)

        try container.encode(self.countryCode, forKey: EncodingKeys.countryCode)
    }
}

extension Region: Equatable {
    static func == (lhs: Region, rhs: Region) -> Bool {
        return lhs.id == rhs.id && lhs.countryId == rhs.countryId
    }
}

extension Region: Hashable {
    public var hashValue: Int { return self.id }
}
