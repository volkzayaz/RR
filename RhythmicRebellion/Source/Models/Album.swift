//
//  Album.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 12/21/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct Album : Decodable {

    let id: Int
    let ownerId: String
    let name: String
    let image: Image
    
}

extension Album: Equatable {
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case ownerId = "owner_id"
        case image = "front_image"
    }
    
    static func ==(lhs: Album, rhs: Album) -> Bool {
        return lhs.ownerId + "\(lhs.id)" == rhs.ownerId + "\(rhs.id)"
    }
    
}
