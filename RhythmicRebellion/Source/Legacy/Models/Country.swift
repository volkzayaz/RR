//
//  Country.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/30/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation


protocol CountryInfo {

    var id: Int { get }
    var code: String { get }
    var name: String { get }

    init(with country: CountryInfo)
}

struct Country: CountryInfo, Codable {

    let id: Int
    let code: String
    let name: String

    enum CodingKeys: String, CodingKey {
        case id
        case code = "country_code"
        case name
    }

    init(with country: CountryInfo) {
        self.id = country.id
        self.code = country.code
        self.name = country.name
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.code = try container.decode(String.self, forKey: .code)
        self.name = try container.decode(String.self, forKey: .name)
    }
}

extension Country: Hashable {

    static func == (lhs: Country, rhs: Country) -> Bool {
        return lhs.id == rhs.id && lhs.code == rhs.code
    }
    public var hashValue: Int { return self.id }
}


struct ProfileCountry: CountryInfo, Codable {

    let id: Int
    let code: String
    let name: String

    enum CodingKeys: String, CodingKey {
        case id
        case code = "country_code"
        case name
    }

    init(with country: CountryInfo) {
        self.id = country.id
        self.code = country.code
        self.name = country.name
    }

    public init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.code = try container.decode(String.self, forKey: .code)
        self.name = try container.decode(String.self, forKey: .name)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(self.id, forKey: .id)
        try container.encode(self.code, forKey: .code)
        try container.encode(self.name, forKey: .name)
    }
}

extension ProfileCountry: Hashable {

    static func == (lhs: ProfileCountry, rhs: ProfileCountry) -> Bool {
        return lhs.id == rhs.id && lhs.code == rhs.code
    }
    public var hashValue: Int { return self.id }
}
