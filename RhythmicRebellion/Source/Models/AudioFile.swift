//
//  AudioFile.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 6/27/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct AudioFile: Codable {
    let id: Int
    let title: String
    let original_name: String
    let bitrate: String
    let duration: Int
    let urlString: String

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case original_name
        case bitrate
        case duration
        case urlString = "link"
    }
}
