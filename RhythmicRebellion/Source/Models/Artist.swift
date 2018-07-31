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
    let subDomain: String?
    let likesCount: Int?
//    let isFollowedByCurrentFan: Bool
    let urlString: String?
    let addons: [Addon]?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case subDomain = "sub_domain"
        case likesCount = "likes_count"
//        case isFollowedByCurrentFan = "is_followed_by_current_fan"
        case urlString = "url"
        case addons = "audio_add_ons"
    }
}
