//
//  TrackState.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 6/28/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct TrackState: Codable, Equatable {

    let hash: String
    var progress: TimeInterval
    var isPlaying: Bool

    init(hash: String, progress: TimeInterval, isPlaying: Bool) {
        self.hash = hash
        self.progress = progress
        self.isPlaying = isPlaying
    }
 
    var isOwn: Bool {
        return hash == WebSocketService.ownSignatureHash
    }
    
}
