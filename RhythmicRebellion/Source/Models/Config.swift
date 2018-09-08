//
//  File.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 9/6/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct Config: Decodable {

    let hobbies: [Hobby]
    let howHearList: [HowHear]

    enum CodingKeys: String, CodingKey {
        case hobbies
        case howHearList = "how_hear"
    }
}
