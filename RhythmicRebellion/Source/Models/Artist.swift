//
//  Artist.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 6/28/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct Artist: Codable {
    let id: String
    let name: String
    let urlString: String?
    let addons: [Addon]?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case urlString = "url"
        case addons = "audio_add_ons"
    }
}
