//
//  PlayerConfig.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 9/17/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct PlayerConfig: Decodable, Equatable {

    let explicitMaterialAudioFile: DefaultAudioFile
    let noAudioFile: DefaultAudioFile
    let noPreviewAudioFile: DefaultAudioFile

    enum CodingKeys: String, CodingKey {
        case explicitMaterialAudioFile = "explicit_material"
        case noAudioFile = "no_file"
        case noPreviewAudioFile = "no_preview"
    }
    
    static func == (lhs: PlayerConfig, rhs: PlayerConfig) -> Bool {
        return true ///currently player config exists in the single instance
    }
    
}
