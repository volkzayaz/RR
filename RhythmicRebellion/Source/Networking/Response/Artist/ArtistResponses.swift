//
//  ArtistResponses.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 12/21/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct ArtistResponse<T: Decodable>: Decodable {
    let data: [T]    
}
