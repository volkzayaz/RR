//
//  CheckAddons.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/11/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct CheckAddons<T: Codable>: Codable {
    
    enum CodingKeys: String, CodingKey {
        case trackId = "srtId"
        case addonRepresentation = "addons"
    }

    let trackId: Int
    let addonRepresentation: [T]

    init(trackID: Int, representation: [T]) {
        self.trackId = trackID
        self.addonRepresentation = representation
    }
    
}

struct AddonState: Codable {
    
    let id: Int
    let typeValue: Int
    let trackId: Int
    
    init(trackId: Int, addon: Addon) {
        self.id = addon.id
        self.typeValue = addon.type.rawValue
        self.trackId = trackId
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case typeValue = "type"
        case trackId = "srtId"
    }
    
}
