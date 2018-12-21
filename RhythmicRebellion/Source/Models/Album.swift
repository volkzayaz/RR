//
//  Album.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 12/21/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct Album : Decodable {
    
    let name: String
    let image: Image
    
}

extension Album {
    
    enum CodingKeys: String, CodingKey {
        case name
        case image = "front_image"
    }
    
}
