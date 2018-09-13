//
//  City.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 9/5/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

protocol CityInfo {

    var id: Int { get }
    var name: String { get }
    var countryCode: String { get }
    var regionCode: String { get }

    init(with city: CityInfo)
}

struct City: CityInfo, Decodable {

    let id: Int
    let name: String
    let countryCode: String
    let regionCode: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case countryCode = "country_code"
        case regionCode = "admin1_code"
    }

    init(with city: CityInfo) {
        self.id = city.id
        self.name = city.name
        self.countryCode = city.countryCode
        self.regionCode = city.regionCode
    }

    public init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)

        self.countryCode = try container.decode(String.self, forKey: .countryCode)
        self.regionCode = try container.decode(String.self, forKey: .regionCode)
    }
}

extension City: Equatable {
    static func == (lhs: City, rhs: City) -> Bool {
        return lhs.id == rhs.id && lhs.countryCode == rhs.countryCode && lhs.regionCode == rhs.regionCode
    }
}

extension City: Hashable {
    public var hashValue: Int { return self.id }
}


struct ProfileCity: CityInfo, Codable {

    let id: Int
    let name: String
    let countryCode: String
    let regionCode: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case countryCode = "countryCode"
        case regionId = "stateId"
        case regionCode = "stateCode"
    }

    init(with city: CityInfo) {
        self.id = city.id
        self.name = city.name
        self.countryCode = city.countryCode
        self.regionCode = city.regionCode
    }

    public init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)

        self.countryCode = try container.decode(String.self, forKey: .countryCode)
        self.regionCode = try container.decode(String.self, forKey: .regionCode)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(self.id, forKey: .id)
        try container.encode(self.name, forKey: .name)

        try container.encode(self.countryCode, forKey: .countryCode)
        try container.encode(self.regionCode, forKey: .regionCode)
    }

}
