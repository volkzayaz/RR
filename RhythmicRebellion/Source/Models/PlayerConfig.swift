//
//  PlayerConfig.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 9/17/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation


struct PlayerConfig: Decodable {

    let explicitMaterialAudioFile: PlayerConfigAudioFile
    let noAudioFile: PlayerConfigAudioFile
    let noPreviewAudioFile: PlayerConfigAudioFile

    enum CodingKeys: String, CodingKey {
        case explicitMaterialAudioFile = "explicit_material"
        case noAudioFile = "no_file"
        case noPreviewAudioFile = "no_preview"
    }
}
