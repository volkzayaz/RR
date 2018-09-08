//
//  Location.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 9/3/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct Location: Codable {

    let country: Country
    let region: Region
    let city: City
    let zip: String

    enum DecodingKeys: String, CodingKey {
        case country
        case region = "state"
        case city
        case zip = "postal"
    }

    enum EncodingKeys: String, CodingKey {
        case country
        case region = "state"
        case city
        case zip
    }

    public init(country: Country, region: Region, city: City, zip: String) {
        self.country = country
        self.region = region
        self.city = city
        self.zip = zip
    }

    public init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: DecodingKeys.self)

        self.country = try container.decode(Country.self, forKey: .country)
        self.region = try container.decode(Region.self, forKey: .region)
        self.city = try container.decode(City.self, forKey: .city)
        self.zip = try container.decode(String.self, forKey: .zip)
    }


    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: EncodingKeys.self)

        try container.encode(self.country, forKey: .country)
        try container.encode(self.region, forKey: .region)
        try container.encode(self.city, forKey: .city)
        try container.encode(self.zip, forKey: .zip)
    }
}

struct DetailedLocation: Decodable {

    let location: Location
    let regions: [Region]
    let cities: [City]

    enum CodingKeys: String, CodingKey {
        case regions = "states"
        case cities
    }

    public init(from decoder: Decoder) throws {

        self.location = try Location(from: decoder)

        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.regions = try container.decode([Region].self, forKey: .regions)
        self.cities = try container.decode([City].self, forKey: .cities)
    }
}
