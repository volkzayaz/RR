//
//  Location.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 9/3/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct ProfileLocation: Codable {

    var country: ProfileCountry
    var region: ProfileRegion?
    var city: ProfileCity?
    var zip: String?

    enum CodingKeys: String, CodingKey {
        case country
        case region = "state"
        case city
        case zip
    }

    public init(country: CountryInfo, region: RegionInfo?, city: CityInfo?, zip: String?) {
        self.country = ProfileCountry(with: country)
        self.region = region != nil ? ProfileRegion(with: region!) : nil
        self.city = city != nil ? ProfileCity(with: city!) : nil
        self.zip = zip
    }

    public init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.country = try container.decode(ProfileCountry.self, forKey: .country)
        self.region = try container.decodeIfPresent(ProfileRegion.self, forKey: .region)
        self.city = try container.decodeIfPresent(ProfileCity.self, forKey: .city)
        self.zip = try container.decodeIfPresent(String.self, forKey: .zip)
    }


    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(self.country, forKey: .country)
        
        try container.encodeIfPresent(self.region, forKey: .region)
        try container.encodeIfPresent(self.city, forKey: .city)
        try container.encodeIfPresent(self.zip, forKey: .zip)
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
    let city: City
    let zip: String
    let regions: [Region]
    let cities: [City]

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
        self.city = try container.decode(City.self, forKey: .city)
        self.zip = try container.decode(String.self, forKey: .zip)

        self.regions = try container.decode([Region].self, forKey: .regions)
        self.cities = try container.decode([City].self, forKey: .cities)
    }
}
