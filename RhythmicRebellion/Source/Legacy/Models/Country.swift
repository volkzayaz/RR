//
//  Country.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/30/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct Country: Codable, Hashable {

    let id: Int
    let code: String
    let name: String

    enum CodingKeys: String, CodingKey {
        case id
        case code = "country_code"
        case name
    }

    init(with country: Country) {
        self.id = country.id
        self.code = country.code
        self.name = country.name
    }
    
    init(withID id: Int, code: String, name: String) {
        self.id = id
        self.code = code
        self.name = name
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.code = try container.decode(String.self, forKey: .code)
        self.name = try container.decode(String.self, forKey: .name)
    }
}

