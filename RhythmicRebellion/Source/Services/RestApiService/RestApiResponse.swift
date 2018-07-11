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

struct AddonsForTracks: RestApiResponse {

    let value: [Int : [Addon]]

    enum CodingKeys: String, CodingKey {
        case data
    }

    init() {
        self.value = [Int : [Addon]]()
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let stringKeyAddonInfo = try container.decode([String : [Addon]].self, forKey: .data)
        var intKeyAddonInfo = [Int : [Addon]]()

        for (stringId, addons) in stringKeyAddonInfo {
            guard let intKey = Int(stringId) else { continue }
            intKeyAddonInfo[intKey] = addons
        }

        self.value = intKeyAddonInfo
    }
}

