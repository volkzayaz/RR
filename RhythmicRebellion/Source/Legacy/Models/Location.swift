//
//  Location.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 9/3/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct ProfileLocation: Codable {

    var country: Country
    var region: Region?
    var city: CityInfo?
    var zip: String?

    enum CodingKeys: String, CodingKey {
        case country
        case region = "state"
        case city
        case zip
    }

    public init(country: Country, region: Region? = nil, city: CityInfo? = nil, zip: String? = nil) {
        self.country = country
        self.region = region
        self.city = city
        self.zip = zip
    }

}

extension ProfileLocation: Equatable {
    static func == (lhs: ProfileLocation, rhs: ProfileLocation) -> Bool {
        return lhs.country == rhs.country && lhs.region == rhs.region && lhs.city == rhs.city && lhs.zip == rhs.zip
    }
}

struct DetailedLocation: Decodable {

    let country: Country
    let region: Region
    let city: CityInfo
    let zip: String
    let regions: [Region]
    let cities: [CityInfo]

    enum CodingKeys: String, CodingKey {
        case country
        case region = "state"
        case city
        case zip = "postal"
        case regions = "states"
        case cities
    }

    public init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.country = try container.decode(Country.self, forKey: .country)
        self.region = try container.decode(Region.self, forKey: .region)
        self.city = try container.decode(CityInfo.self, forKey: .city)
        self.zip = try container.decode(String.self, forKey: .zip)

        self.regions = try container.decode([Region].self, forKey: .regions)
        self.cities = try container.decode([CityInfo].self, forKey: .cities)
    }
}
