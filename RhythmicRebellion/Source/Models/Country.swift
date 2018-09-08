//
//  Country.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/30/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct Country: Codable {

    let id: Int
    let code: String
    let name: String

    enum DecodingKeys: String, CodingKey {
        case id
        case code = "country_code"
        case name
    }

    enum EncodingKeys: String, CodingKey {
        case id
        case code = "countryCode"
        case name
    }

    public init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: DecodingKeys.self)

        self.id = try container.decode(Int.self, forKey: DecodingKeys.id)
        self.code = try container.decode(String.self, forKey: DecodingKeys.code)
        self.name = try container.decode(String.self, forKey: DecodingKeys.name)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: EncodingKeys.self)

        try container.encode(self.id, forKey: EncodingKeys.id)
        try container.encode(self.code, forKey: EncodingKeys.code)
        try container.encode(self.name, forKey: EncodingKeys.name)
    }
}

extension Country: Equatable {
    static func == (lhs: Country, rhs: Country) -> Bool {
        return lhs.id == rhs.id && lhs.code == rhs.code
    }
}

extension Country: Hashable {
    public var hashValue: Int { return self.id }
}
