//
//  RestApiResponse.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/11/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import Alamofire

public protocol RestApiResponse: Decodable {
    init()
}

struct AddonsForTracksResponse: RestApiResponse {

    let value: [Int : [Addon]]

    enum CodingKeys: String, CodingKey {
        case data
    }

    init() {
        self.value = [Int : [Addon]]()
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        var intKeyAddonInfo = [Int : [Addon]]()

        do {
            let stringKeyAddonInfo = try container.decode([String : [Addon]].self, forKey: .data)

            for (stringId, addons) in stringKeyAddonInfo {
                guard let intKey = Int(stringId) else { continue }
                intKeyAddonInfo[intKey] = addons
            }

            self.value = intKeyAddonInfo
        } catch (let error) {
            guard let emptyAddons = try? container.decodeIfPresent([Addon].self, forKey: .data), emptyAddons?.isEmpty ?? false else { throw error }
            self.value = intKeyAddonInfo
        }
    }
}

struct FanUserResponse: RestApiResponse {

    let user: User?

    enum CodingKeys: String, CodingKey {
        case data
    }

    enum DataCodingKeys: String, CodingKey {
        case guest
    }

    init () {
        self.user = nil
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let dataContainer = try container.nestedContainer(keyedBy: DataCodingKeys.self, forKey: .data)

        let isGuest = try dataContainer.decode(Bool.self, forKey: .guest)

        if isGuest {
            self.user = try container.decode(GuestUser.self, forKey: .data)
        } else {
            self.user = try container.decode(FanUser.self, forKey: .data)
        }
    }
}

struct FanLoginResponse: RestApiResponse {

    let user: User?

    enum CodingKeys: String, CodingKey {
        case user
    }

    enum DataCodingKeys: String, CodingKey {
        case guest
    }

    init () {
        self.user = nil
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let userContainer = try container.nestedContainer(keyedBy: DataCodingKeys.self, forKey: .user)

        let isGuest = try userContainer.decode(Bool.self, forKey: .guest)

        if isGuest {
            self.user = try container.decode(GuestUser.self, forKey: .user)
        } else {
            self.user = try container.decode(FanUser.self, forKey: .user)
        }
    }
}

