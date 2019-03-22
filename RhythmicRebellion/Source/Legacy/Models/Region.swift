//
//  State.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 9/4/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

protocol RegionInfo {

    var id: Int { get }
    var code: String { get }
    var name: String { get }
    var countryCode: String { get }

    init?(with region: RegionInfo?)
}

struct Region: RegionInfo, Decodable {

    let id: Int
    let code: String
    let name: String
    let countryCode: String

    enum DecodingKeys: String, CodingKey {
        case id
        case code = "admin1_code"
        case name
        case countryId = "country_id"
        case countryCode = "country_code"
    }

    init?(with region: RegionInfo?) {
        
        guard let region = region else { return nil }
        
        self.id = region.id
        self.code = region.code
        self.name = region.name
        self.countryCode = region.countryCode
    }

    public init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: DecodingKeys.self)

        self.id = try container.decode(Int.self, forKey: DecodingKeys.id)
        self.code = try container.decode(String.self, forKey: DecodingKeys.code)
        self.name = try container.decode(String.self, forKey: DecodingKeys.name)

        self.countryCode = try container.decode(String.self, forKey: DecodingKeys.countryCode)
    }

}

extension Region: Hashable {

    static func == (lhs: Region, rhs: Region) -> Bool {
        return lhs.id == rhs.id && lhs.countryCode == rhs.countryCode
    }

    public var hashValue: Int { return self.id }
}


struct ProfileRegion: RegionInfo, Codable {

    let id: Int
    let code: String
    let name: String
    let countryCode: String

    enum CodingKeys: String, CodingKey {
        case id
        case code = "stateCode"
        case name
        case countryCode = "countryCode"
    }

    init?(with region: RegionInfo?) {
        
        guard let region = region else {
            return nil
        }
        
        self.id = region.id
        self.code = region.code
        self.name = region.name
        self.countryCode = region.countryCode
    }

    public init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.code = try container.decode(String.self, forKey: .code)
        self.name = try container.decode(String.self, forKey: .name)

        self.countryCode = try container.decode(String.self, forKey: .countryCode)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(self.id, forKey: .id)
        try container.encode(self.code, forKey: .code)
        try container.encode(self.name, forKey: .name)

        try container.encode(self.countryCode, forKey: .countryCode)
    }
}

extension ProfileRegion: Hashable {

    static func == (lhs: ProfileRegion, rhs: ProfileRegion) -> Bool {
        return lhs.id == rhs.id && lhs.countryCode == rhs.countryCode
    }

    public var hashValue: Int { return self.id }
}
